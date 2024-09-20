with Ada.Numerics.Discrete_Random;
with Termios;

procedure MineSweeper is
   Non_Terminal  : exception;

   STDIN         : constant Integer := Termios.STDIN_FILENO;
   ESC_CODE      : constant Character := Character'Val (16#1B#);
   CR_CODE       : constant Character := Character'Val (16#0D#);
   NEW_LINE_CODE : constant Character := Character'Val (16#0A#);
   BOMB_PERCENT  : constant Positive  := 25;

   type Mine_Field_Bit_State  is (Closed, Open, Flagged) with Default_Value => Closed;
   type Mine_Field_Height     is range 0 .. 10 with Default_Value => 0; -- Some of the terminal stuff are hardcoded
   type Mine_Field_Width      is range 0 .. 10 with Default_Value => 0;
   type Mine_Field_Bit        is range 0 .. 4  with Default_Value => 0;
   type Mine_Field_State      is array (Mine_Field_Height, Mine_Field_Width) of Mine_Field_Bit_State;
   type Mine_Field            is array (Mine_Field_Height, Mine_Field_Width) of Mine_Field_Bit;
   package Mine_Field_Height_Random is new Ada.Numerics.Discrete_Random (Mine_Field_Height);
   package Mine_Field_Width_Random  is new Ada.Numerics.Discrete_Random (Mine_Field_Width);

   RGenerator_Height : Mine_Field_Height_Random.Generator;
   RGenerator_Width  : Mine_Field_Width_Random.Generator;
   
   Field_State     : Mine_Field_State;
   Field           : Mine_Field;
   CursorH         : Mine_Field_Height;
   CursorW         : Mine_Field_Width;
   Started         : Boolean     := False;
   Read_Char       : Character   := Character'Val (0);

   function Is_Bomb (H : Mine_Field_Height; W : Mine_Field_Width) return Boolean is
   begin
      return (if Field (H, W) = 4 then True else False);
   end Is_Bomb;

   procedure Check_Field (CH : Mine_Field_Height; CW : Mine_Field_Width) is
      type Bit is record
         H : Mine_Field_Height;
         W : Mine_Field_Width;
      end record;
      type Row is array (0 .. 2) of Bit;

      procedure Checked_Inc (H : Mine_Field_Height; W : Mine_Field_Width) is
      begin
         if (Field (H, W) < Mine_Field_Bit'Last) then Field (H, W) := @ + 1; end if;
      end Checked_Inc;
  
      Top, Middle, Bottom : Row;
   begin
      -- x x x
      -- x @ x
      -- x x x

      -- Check if there is atleast one more Row to upwards, if there isnt middle will do it
      if CH /= 0 then
         -- Top Left
         Top (0).H := CH - 1;
         Top (0).W := (if CW = 0 then 0 else CW - 1);
         if Is_Bomb (Top (0).H, Top (0).W) and CW /= 0 then Checked_Inc(CH, CW); end if;

         -- Top Middle
         Top (1).H := CH - 1;
         Top (1).W := CW;
         if Is_Bomb (Top (1).H, Top (1).W) then Checked_Inc(CH, CW); end if;

         -- Top Right
         Top (2).H := CH - 1;
         Top (2).W := (if CW = Mine_Field_Width'Last then Mine_Field_Width'Last else CW + 1);
         if Is_Bomb (Top (2).H, Top (2).W) and CW /= Mine_Field_Width'Last then Checked_Inc(CH, CW); end if;
      end if;

      -- Middle Left
      Middle (0).H := CH;
      Middle (0).W := (if CW = 0 then 0 else CW - 1);
      if Is_Bomb (Middle (0).H, Middle (0).W) and CW /= 0 then Checked_Inc(CH, CW); end if;

      -- Middle Middle, is the current pos so ignore

      -- Middle Right
      Middle (2).H := CH;
      Middle (2).W := (if CW = Mine_Field_Width'Last then Mine_Field_Width'Last else CW + 1);
      if Is_Bomb (Middle (2).H, Middle (2).W) and CW /= Mine_Field_Width'Last then Checked_Inc(CH, CW); end if;

      -- Check if there is atleast one more Row to downvards, if there isnt middle will do it
      if CH /= Mine_Field_Height'Last then
         -- Bottom Left
         Bottom (0).H := CH + 1;
         Bottom (0).W := (if CW = 0 then 0 else CW - 1);
         if Is_Bomb (Bottom (0).H, Bottom (0).W) and CW /= 0 then Checked_Inc(CH, CW); end if;

         -- Bottom Middle
         Bottom (1).H := CH + 1;
         Bottom (1).W := CW;
         if Is_Bomb (Bottom (1).H, Bottom (1).W) then Checked_Inc(CH, CW); end if;

         -- Bottom Right
         Bottom (2).H := CH + 1;
         Bottom (2).W := (if CW = Mine_Field_Width'Last then Mine_Field_Width'Last else CW + 1);
         if Is_Bomb (Bottom (2).H, Bottom (2).W) and CW /= Mine_Field_Width'Last then Checked_Inc(CH, CW); end if;
      end if;
   end Check_Field;

   procedure Generate_Field is
      BOMB_COUNT  : constant Positive := (10 * 10 * BOMB_PERCENT) / 100;
      Rando_BitH  : Mine_Field_Height;
      Rando_BitW  : Mine_Field_Width;
   begin
      for H in Field'Range (1) loop
         for W in Field'Range (2) loop
            Field_State (H, W) := Closed;
            Field (H, W) := 0;
         end loop;
      end loop;

      for B in 1 .. BOMB_COUNT loop
         Rando_BitH := Mine_Field_Height_Random.Random (RGenerator_Height);
         Rando_BitW := Mine_Field_Width_Random.Random  (RGenerator_Width);
         Field (Rando_BitH, Rando_BitW) := 4;
      end loop;

      Field (CursorH, CursorW) := 0;

      for H in Field'Range (1) loop
         for W in Field'Range (2) loop
            if not Is_Bomb (H, W) then Check_Field (H, W); end if;
         end loop;
      end loop;
   end Generate_Field;

   procedure Show_Field is
   begin
      for H in Field'Range (1) loop
         for W in Field'Range (2) loop
            Termios.Write_Char (STDIN, ' ');
            if (Field_State (H, W) = Flagged) then
               Termios.Write_Char (STDIN, 'F');
            elsif (Field_State (H, W) = Open) then
               Termios.Write_Char (STDIN, '+');
            elsif (Field (H, W) = 4) then
                  Termios.Write_Char (STDIN, '!');
            else  
               case Field (H, W) is
                  when 0 => Termios.Write_Char (STDIN, ' ');
                  when 1 => Termios.Write_Char (STDIN, '1');
                  when 2 => Termios.Write_Char (STDIN, '2');
                  when 3 => Termios.Write_Char (STDIN, '3');
                  when 4 => Termios.Write_Char (STDIN, '*');
               end case;
            end if;
            Termios.Write_Char (STDIN, ' ');
         end loop;
         Termios.Write_Char (STDIN, CR_CODE);
         Termios.Write_Char (STDIN, NEW_LINE_CODE);
      end loop;
   end Show_Field;

   procedure Print_Field is
   begin
      for H in Field'Range (1) loop
         for W in Field'Range (2) loop
            if (H = CursorH and W = CursorW) then Termios.Write_Char (STDIN, '[');
            else Termios.Write_Char (STDIN, ' '); end if;
            case Field (H, W) is
               when 0 => Termios.Write_Char (STDIN, 
                  (  if Field_State (H, W) = Closed then '.'
                     elsif Field_State (H, W) = Open then ' '
                     else 'F'
                  ));
               when 1 => Termios.Write_Char (STDIN, 
                  (  if Field_State (H, W) = Closed then '.'
                     elsif Field_State (H, W) = Open then '1'
                     else 'F'
                  ));
               when 2 => Termios.Write_Char (STDIN, 
                  (  if Field_State (H, W) = Closed then '.'
                     elsif Field_State (H, W) = Open then '2'
                     else 'F'
                  ));
               when 3 => Termios.Write_Char (STDIN, 
                  (  if Field_State (H, W) = Closed then '.'
                     elsif Field_State (H, W) = Open then '3'
                     else 'F'
                  ));
               when 4 => Termios.Write_Char (STDIN, 
                  (  if Field_State (H, W) = Closed then '.'
                     elsif Field_State (H, W) = Open then '!'
                     else 'F'
                  ));
                  if Field_State (H, W) = Open then 
                     Started := False; 

                     Termios.Write_Char (STDIN, ' ');                    
                     Termios.Write_Char (STDIN, ESC_CODE);
                     Termios.Write_Char (STDIN, '[');
                     Termios.Write      (STDIN, "12");
                     Termios.Write_Char (STDIN, 'D');
                     Termios.Write_Char (STDIN, ESC_CODE);
                     Termios.Write_Char (STDIN, '[');
                     Termios.Write      (STDIN, "12");
                     Termios.Write_Char (STDIN, 'B');
                     Termios.Write (STDIN, "Dead, Press <e> to show all.");
                     Termios.Write_Char (STDIN, ESC_CODE);
                     Termios.Write_Char (STDIN, '[');
                     Termios.Write      (STDIN, "12");
                     Termios.Write_Char (STDIN, 'A');
                  end if;
            end case;
            if (H = CursorH and W = CursorW) then Termios.Write_Char (STDIN, ']');
            else Termios.Write_Char (STDIN, ' '); end if;
          end loop;

         Termios.Write_Char (STDIN, CR_CODE);
         Termios.Write_Char (STDIN, NEW_LINE_CODE);
         end loop;
   end Print_Field;
begin
   if not Termios.Is_Terminal (STDIN) then
      raise Non_Terminal with "Please use a terminal.";
   end if;

   Mine_Field_Height_Random.Reset (RGenerator_Height);
   Mine_Field_Width_Random.Reset (RGenerator_Width);
   
   Termios.Save_State (STDIN);
   Termios.Set_State_Raw (STDIN);

   Termios.Write_Char (STDIN, NEW_LINE_CODE);
   loop
      Read_Char := Termios.Read_Char (STDIN);
      Termios.Write_Char (STDIN, ESC_CODE);
      Termios.Write_Char (STDIN, '[');
      Termios.Write      (STDIN, "11");
      Termios.Write_Char (STDIN, 'A');
      case Read_Char is
         when 'q' => exit;
         when 'e' => Show_Field; exit;
         when 'w' => CursorH := (if @ = 0 then Mine_Field_Height'Last else @ - 1);
         when 's' => CursorH := (if @ = Mine_Field_Height'Last then 0 else @ + 1);
         when 'd' => CursorW := (if @ = Mine_Field_Width'Last then 0 else @ + 1);
         when 'a' => CursorW := (if @ = 0 then Mine_Field_Width'Last else @ - 1);
         when 'f' => Field_State (CursorH, CursorW) := Flagged;
         when ' ' => 
            if (Started) then Field_State (CursorH, CursorW) := Open;
            else Generate_Field; Field_State (CursorH, CursorW) := Open; Started := True; end if;
         when others => null;
      end case;
      Print_Field;
      
   end loop;

   Termios.Set_State_Saved (STDIN);
end MineSweeper;

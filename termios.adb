with Interfaces.C; use Interfaces.C;
with System.CRTL; use System;

package body Termios is
   function Is_Terminal (Fd : Integer) return Boolean is
   begin
      return (if CRTL.isatty (Fd) = 1 then True else False);
   end Is_Terminal;

   procedure Save_State (Fd : Integer) is
   begin
      if tcgetattr (int (Fd), Old_State'Address) = -1 then
         raise Failed_To_Get_Tc_Attrib 
            with "Failed to get terminal attribute (tcgetattr)!";
      end if;
   end Save_State; 
   
   procedure Set_State_Saved (Fd : Integer) is
   begin
      Current_State := Old_State;
      if tcsetattr (int (Fd), int (TCSAFLUSH), Current_State'Address) = -1 then
         raise Failed_To_Set_Tc_Attrib 
            with "Failed to set terminal attribute (tcsetattr)!";
      end if;
   end Set_State_Saved;
   
   procedure Set_State_Raw (Fd: Integer) is
   begin
      cfmakeraw (Current_State'Address);
      if tcsetattr (int (Fd), int (TCSAFLUSH), Current_State'Address) = -1 then
         raise Failed_To_Set_Tc_Attrib 
            with "Failed to set terminal attribute (tcsetattr)!";
      end if;
   end Set_State_Raw; 

   function Read_Char (Fd : Integer) return Character is
      Read_Char : Character := Character'Val (0);
   begin
      if Integer (CRTL.read (Fd, Read_Char'Address, 1)) = -1 then
         raise Failed_To_Read 
            with "Failed to read char from " & Fd'Image;
      end if;
      return Read_Char;
   end Read_Char;

   procedure Write_Char (Fd : Integer; Ch : Character) is
   begin
      if Integer (CRTL.write (Fd, Ch'Address, 1)) = -1 then
         raise Failed_To_Write
            with "Failed to write char to " & Fd'Image;
      end if;
   end Write_Char; 

   procedure Write (Fd : Integer; Str : String) is
   begin
      if Integer (CRTL.write (Fd, Str'Address, Str'Length)) = -1 then
         raise Failed_To_Write
            with "Failed to write string to " & Fd'Image;
      end if;
   end Write; 
end Termios;

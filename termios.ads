with Interfaces.C; use Interfaces.c;
with System; use System;

package Termios is
   Failed_To_Get_Tc_Attrib : exception;
   Failed_To_Set_Tc_Attrib : exception;
   Failed_To_Read          : exception;
   Failed_To_Write         : exception;
   
   STDIN_FILENO            : constant Integer := 0;

   type C_Termios is private;

   function  Is_Terminal     (fd : Integer) return Boolean;
   procedure Save_State      (fd : Integer);
   procedure Set_State_Saved (fd : Integer);
   procedure Set_State_Raw   (fd : Integer);

   function  Read_Char  (Fd : Integer) return Character; 
   procedure Write_Char (Fd : Integer; Ch : Character); 
   procedure Write      (Fd : Integer; Str : String); 
private
   TCSAFLUSH    : constant Integer := 2;

   subtype speed_t is unsigned;
   type C_Termios is record
      c_iflag  : unsigned;
      c_oflag  : unsigned;
      c_cflag  : unsigned;
      c_lflag  : unsigned;
      c_line   : unsigned_char;
      c_cc     : Interfaces.C.char_array (0 .. 31);
      c_ispeed : speed_t;
      c_ospeed : speed_t;
   end record;
   pragma Convention (C, C_Termios);
 
   function tcgetattr (fd : int; termios_p : Address) return int;
   pragma Import (C, tcgetattr, "tcgetattr");

   function tcsetattr
     (fd : int; action : int; termios_p : Address) return int;
   pragma Import (C, tcsetattr, "tcsetattr");

   procedure cfmakeraw (termios_p : Address);
   pragma Import (C, cfmakeraw, "cfmakeraw");  

   Old_State, Current_State : C_Termios;
    
end Termios;

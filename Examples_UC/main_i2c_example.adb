with Interfaces;
use type Interfaces.Unsigned_16;

with STM32F7_Disco.I2c; use STM32F7_Disco.I2c;

--  Para la pantalla
with LCD_Std_Out;
with HAL.Bitmap; use HAL.Bitmap;
with BMP_Fonts;
with STM32.Board; use STM32.Board; -- display

with Ada.Real_Time; use Ada.Real_Time;

with Last_Chance_Handler;  pragma Unreferenced (Last_Chance_Handler);

procedure Main_I2C_Example is

   BG : constant Bitmap_Color := (Alpha => 255, others => 64);

   Estado : I2C_Status;

   --  array de de valores entre 0 y 255 -- 8 bits 2#00000000#
   Dato_Recibido : Data_IO := (0, 0);

   --  Comando de medicion continua 'D' --> 68 --> 01000100
   Dato_Enviado : constant Data_IO := (2, 0);

   --  Direccion Lidar 0x60 --> 2#1_100_000# --> 2#11_000_000#
   Dir_Brujula : constant I2C_Dir := 2#11_000_000#;

   Resultado : Interfaces.Unsigned_16;

begin

   --  Initialize LCD
   Display.Initialize;
   Display.Initialize_Layer (1, ARGB_8888);
   LCD_Std_Out.Set_Font (BMP_Fonts.Font16x24);
   LCD_Std_Out.Current_Background_Color := BG;

   STM32F7_Disco.I2c.Begin_Transmision (100_000);
   loop

      LCD_Std_Out.Clear_Screen;
      LCD_Std_Out.Put_Line ("Comienzo");

      STM32F7_Disco.I2c.Write (Dir_Brujula, Dato_Enviado);
      LCD_Std_Out.Put_Line ("Solicitud de informacion enviada");

      STM32F7_Disco.I2c.Read (Dir_Brujula, Dato_Recibido);

      Estado := Get_Status;

      LCD_Std_Out.Put_Line (" *** Recepcion *** ");
      LCD_Std_Out.Put_Line ("Estado en RECEPCION--> " & Estado'Image);

      --  operaciones para obtener los grados a girar a la derecha hasta consgeguir el norte
      Resultado := Interfaces.Unsigned_16 (Dato_Recibido (0));
      Resultado := Interfaces.Shift_Left  (Resultado, 8);
      Resultado := (Resultado + Interfaces.Unsigned_16 (Dato_Recibido (1)));
      Resultado := Resultado / 10;

      LCD_Std_Out.Put_Line ("Muestra los datos");
      LCD_Std_Out.Put_Line ("Resultado: " & Integer (Resultado)'Image);

      delay until Ada.Real_Time.Clock + To_Time_Span (0.5);
   end loop;
end Main_I2C_Example;

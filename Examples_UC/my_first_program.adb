with STM32.Board;
with HAL.Bitmap;
with BMP_Fonts;
with LCD_Std_Out;
with HAL;
with Ada.Real_Time; use Ada.Real_Time;

procedure My_First_Program is
   BG : constant HAL.Bitmap.Bitmap_Color := (Alpha => 255, others => 64);

begin
   STM32.Board.Display.Initialize;
   STM32.Board.Display.Initialize_Layer (1, HAL.Bitmap.ARGB_8888);
   LCD_Std_Out.Set_Font (BMP_Fonts.Font16x24);
   LCD_Std_Out.Current_Background_Color := BG;
   STM32.Board.Initialize_LEDs;
   loop
      LCD_Std_Out.Clear_Screen;
      STM32.Board.All_LEDs_On;
      LCD_Std_Out.Put (X   => 200, Y   => 240, Msg => "Todos los leds ENCENDIDOS");
      delay until Ada.Real_Time.Clock + To_Time_Span (1.0);

      LCD_Std_Out.Clear_Screen;
      STM32.Board.All_LEDs_Off;
      LCD_Std_Out.Put (X   => 200,
                       Y   => 240,
                       Msg => "Todos los leds APAGADOS");
      delay until Ada.Real_Time.Clock + To_Time_Span (1.0);
   end loop;

end My_First_Program;

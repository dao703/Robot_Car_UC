
with Last_Chance_Handler;  pragma Unreferenced (Last_Chance_Handler);

with STM32.Device; use STM32.Device;

--  Display
with STM32.Board;           use STM32.Board;
with HAL.Bitmap;            use HAL.Bitmap;
with BMP_Fonts;             use BMP_Fonts;
with LCD_Std_Out;

with STM32F7_Disco.ADC;

with Ada.Real_Time;        use Ada.Real_Time;
with HAL;


procedure Main_ADC_Example is
   BG : constant Bitmap_Color := (Alpha => 255, others => 64);
   Raw : HAL.UInt16 := 0; -- adc instruction

begin
   --  Initialize LCD
   Display.Initialize;
   Display.Initialize_Layer (1, ARGB_8888);
   LCD_Std_Out.Set_Font (Font16x24);
   LCD_Std_Out.Current_Background_Color := BG;

   STM32F7_Disco.ADC.Configure_ADC_1_Channel_6;
   loop
      LCD_Std_Out.Clear_Screen;
      LCD_Std_Out.Put_Line (" Main adc own libraries");
      STM32F7_Disco.ADC.Start_Conversion_ADC_1_Channel_6; -- adc instruction
      Raw := STM32F7_Disco.ADC.Get_Value_ADC_1_Channel_6;
      LCD_Std_Out.Put_Line (Raw'Image);

      delay until Clock + To_Time_Span (0.3);
   end loop;
end Main_ADC_Example;

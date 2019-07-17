
--  Display
with STM32.Board;           use STM32.Board;
with HAL.Bitmap;            use HAL.Bitmap;
with BMP_Fonts;             use BMP_Fonts;
with LCD_Std_Out;

with STM32.DAC;
with STM32.Device;
with STM32.GPIO;
use STM32.GPIO;


with Ada.Real_Time; use Ada.Real_Time;
with HAL;
with HAL.GPIO;

procedure Main_DAC_Example is

   BG : constant Bitmap_Color := (Alpha => 255, others => 64);
   Analog_Mode   : STM32.GPIO.GPIO_Port_Configuration := (Mode => STM32.GPIO.Mode_Analog,
                                                          Output_Type  => STM32.GPIO.Push_Pull,  --  Push_Pull / open drain
                                                          Speed       => STM32.GPIO.Speed_2MHz,  -- Speed_2MHz,  Speed_25MHz, Speed_50MHz, Speed_100MHz
                                                          Resistors   => STM32.GPIO.Floating);
   --  Note that Channel 1 is tied to GPIO pin PA4, and Channel 2 to PA5
   Output_Pin : GPIO_Point := STM32.Device.PA4;
begin

   --  Initialize LCD
   Display.Initialize;
   Display.Initialize_Layer (1, ARGB_8888);
   LCD_Std_Out.Set_Font (Font16x24);
   LCD_Std_Out.Current_Background_Color := BG;

   STM32.Device.Enable_Clock (Output_Pin); -- adc instruction

   STM32.GPIO.Configure_IO (Output_Pin, Analog_Mode); -- adc instruction
   --  Note that Channel 1 is tied to GPIO pin PA4, and Channel 2 to PA5

   STM32.DAC.Enable (This    => STM32.Device.DAC_1,
                     Channel => STM32.DAC.Channel_1);

   STM32.GPIO.Configure_IO (Output_Pin, Analog_Mode); -- adc instruction






      STM32.DAC.Set_Output (This       => STM32.Device.DAC_1,
                            Channel    => STM32.DAC.Channel_1,
                            Value      => HAL.UInt32'Last,
                            Resolution => STM32.DAC.DAC_Resolution_12_Bits,
                            Alignment  => STM32.DAC.Left_Aligned);

      delay until Ada.Real_Time.Clock + To_Time_Span (5.0);



end Main_DAC_Example;

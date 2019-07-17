with STM32.Device;
with STM32.GPIO;
package body STM32F7_Disco.ADC is

   -----------------------------------------
   ------- Cofigures the ADC   -------------
   -----------------------------------------
   procedure Configure_ADC_1_Channel_6  is

   begin

      STM32.Device.Enable_Clock (Input1); -- adc instruction
      STM32.GPIO.Configure_IO (Input1, Analog_Mode); -- adc instruction
      STM32.Device.Enable_Clock (Converter); -- adc instruction

      STM32.Device.Reset_All_ADC_Units; -- adc instruction

      Configure_Common_Properties -- adc instruction
        (Mode           => Independent, -- adc instruction
         Prescalar      => PCLK2_Div_2, -- adc instruction
         DMA_Mode       => Disabled, -- adc instruction
         Sampling_Delay => Sampling_Delay_15_Cycles); -- adc instruction

      Configure_Unit -- adc instruction
        (Converter, -- adc instruction
         Resolution => ADC_Resolution_12_Bits, -- adc instruction
         Alignment  => Right_Aligned); -- adc instruction

      Configure_Regular_Conversions -- adc instruction
        (Converter, -- adc instruction
         Continuous  => False, -- adc instruction
         Trigger     => Software_Triggered, -- adc instruction
         Enable_EOC  => False, -- adc instruction  false
         Conversions => All_Regular_Conversions); -- adc instruction

      Enable (Converter); -- adc instruction

   end Configure_ADC_1_Channel_6;

   -----------------------------------------
   ---- Initialize the conversion  ---------
   -----------------------------------------
   procedure Start_Conversion_ADC_1_Channel_6 is
   begin
      Start_Conversion (Converter); -- adc instruction
   end Start_Conversion_ADC_1_Channel_6;

   -----------------------------------------
   ---- Returns the input value  ---------
   -----------------------------------------
   function Get_Value_ADC_1_Channel_6 return UInt16  is
   begin
      Poll_For_Status (Converter, Regular_Channel_Conversion_Complete, Successful); -- adc instruction

      return UInt16 (Conversion_Value (Converter));
   end Get_Value_ADC_1_Channel_6;



end STM32F7_Disco.ADC;

with STM32.ADC;    use STM32.ADC;
with HAL;          use HAL;
with HAL.GPIO;
with STM32.Device;
with STM32.GPIO;


package STM32F7_Disco.ADC is


   --  Channels are mapped to GPIO_Point values as follows.  See
   --  the STM32F40x datasheet, Table 7. "STM32F40x pin and ball definitions"
   --
   --  Channel    ADC    ADC    ADC
   --    #         1      2      3
   --
   --    0        PA0    PA0    PA0
   --    1        PA1    PA1    PA1
   --    2        PA2    PA2    PA2
   --    3        PA3    PA3    PA3
   --    4        PA4    PA4    PF6
   --    5        PA5    PA5    PF7
   --    6        PA6    PA6    PF8
   --    7        PA7    PA7    PF9
   --    8        PB0    PB0    PF10
   --    9        PB1    PB1    PF3
   --   10        PC0    PC0    PC0
   --   11        PC1    PC1    PC1
   --   12        PC2    PC2    PC2
   --   13        PC3    PC3    PC3
   --   14        PC4    PC4    PF4
   --   15        PC5    PC5    PF5


   Converter     : Analog_To_Digital_Converter renames STM32.Device.ADC_1;
   Input_Channel : constant Analog_Input_Channel := 6;
   Input1        : constant STM32.GPIO.GPIO_Point := STM32.Device.PA6; -- adc instruction, PA6 port ( Channel 1 -- Pin PA6 )
   --  Analog_Mode   : STM32.GPIO.GPIO_Port_Configuration (STM32.GPIO.Mode_Analog);
   Analog_Mode   : STM32.GPIO.GPIO_Port_Configuration := (Mode => STM32.GPIO.Mode_Analog,
                                                          Output_Type  => STM32.GPIO.Push_Pull,  --  Push_Pull / open drain
                                                          Speed       => STM32.GPIO.Speed_2MHz,  -- Speed_2MHz,  Speed_25MHz, Speed_50MHz, Speed_100MHz
                                                          Resistors   => STM32.GPIO.Floating);

   All_Regular_Conversions : constant Regular_Channel_Conversions :=
     (1 => (Channel => Input_Channel, Sample_Time => Sample_144_Cycles));

   Raw : UInt16 := 0;

   Successful : Boolean;

   procedure Configure_ADC_1_Channel_6;

   procedure Start_Conversion_ADC_1_Channel_6;

   function Get_Value_ADC_1_Channel_6 return UInt16;


end STM32F7_Disco.ADC;

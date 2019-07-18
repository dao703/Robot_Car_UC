with STM32.Device;
with STM32.GPIO;
with STM32.DAC;

package body STM32F7_Disco.DAC is


   Analog_Mode   : STM32.GPIO.GPIO_Port_Configuration := (Mode => STM32.GPIO.Mode_Analog,
                                                          Output_Type  => STM32.GPIO.Push_Pull,  --  Push_Pull / open drain
                                                          Speed       => STM32.GPIO.Speed_2MHz,  -- Speed_2MHz,  Speed_25MHz, Speed_50MHz, Speed_100MHz
                                                          Resistors   => STM32.GPIO.Floating);


   Output_Channel : constant STM32.DAC.DAC_Channel := STM32.DAC.Channel_1;  -- arbitrary
   Resolution : constant STM32.DAC.DAC_Resolution := STM32.DAC.DAC_Resolution_12_Bits;

   -----------------------------------------
   ------- Cofigures pin PA4 as DAC  ------
   -----------------------------------------
   procedure Initilize_DAC_PA4  is

   begin

      --  Note that Channel 1 is tied to GPIO pin PA4, and Channel 2 to PA5
      STM32.Device.Enable_Clock (STM32.Device.DAC_Channel_1_IO);

      STM32.GPIO.Configure_IO (STM32.Device.DAC_Channel_1_IO, Analog_Mode);

      STM32.Device.Enable_Clock (STM32.Device.DAC_1);

      STM32.Device.Reset (STM32.Device.DAC_1);

      STM32.DAC.Select_Trigger (STM32.Device.DAC_1, Output_Channel, STM32.DAC.Software_Trigger);

      STM32.DAC.Enable_Trigger (STM32.Device.DAC_1, Output_Channel);

      STM32.DAC.Enable (STM32.Device.DAC_1, Output_Channel);

   end Initilize_DAC_PA4;

   -----------------------------------------
   ---- Set the output value in PA4  -------
   -----------------------------------------
   procedure Set_Value_DAC_PA4 (V : UInt32) is
   begin
      STM32.DAC.Set_Output   (STM32.Device.DAC_1,
                              Output_Channel,
                              V,  -- 1_047_483_647 --> 1.03V | 1_000_045 --> 05V
                              Resolution,
                              STM32.DAC.Right_Aligned);

      STM32.DAC.Trigger_Conversion_By_Software (STM32.Device.DAC_1, Output_Channel);

   end Set_Value_DAC_PA4;



end STM32F7_Disco.DAC;

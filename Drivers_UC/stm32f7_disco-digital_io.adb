with STM32.GPIO;


package body STM32F7_Disco.Digital_IO is

   ----------------------------------------------------------------
   --  Configure the pin as input or output
   ----------------------------------------------------------------
   procedure Configure_Pin (Pin : in GPIO_Point; Mode : Pin_Mode) is
      Actual_Pin : GPIO_Point := Pin;
      State : Boolean := False;
   begin
      if Mode = Input then
         --  input pin
         State := STM32.GPIO.Set_Mode (Actual_Pin, HAL.GPIO.Input);
      else
         --  output pin
         STM32.Device.Enable_Clock (Actual_Pin);

         STM32.GPIO.Configure_IO
           (Actual_Pin,
            (Mode        => STM32.GPIO.Mode_Out,
             Output_Type => STM32.GPIO.Push_Pull,
             Speed       => STM32.GPIO.Speed_100MHz,
             Resistors   => STM32.GPIO.Floating));
      end if;

   end Configure_Pin;

   ----------------------------------------------------------------
   --  Get the pin value
   ----------------------------------------------------------------
   function Digital_Read (Pin : in GPIO_Point) return Boolean is
   begin
      return STM32.GPIO.Set (Pin);
   end Digital_Read;

   ----------------------------------------------------------------
   --  Set the pin value
   ----------------------------------------------------------------
   procedure Digital_Write (Pin : GPIO_Point; Value : Boolean) is
      Actual_Pin : GPIO_Point := Pin;
   begin
      if Value then
         --  turn on the pin
         STM32.GPIO.Set (Actual_Pin);
      else
         --  turn off the pin
         STM32.GPIO.Clear (Actual_Pin);
      end if;
   end Digital_Write;

   ----------------------------------------------------------------
   --  Change the value of a pin
   ----------------------------------------------------------------
   procedure Toogle_Pin (Pin : in GPIO_Point) is
      This : GPIO_Point := Pin;
   begin
      STM32.GPIO.Toggle (This);
   end Toogle_Pin;


end STM32F7_Disco.Digital_IO;

with STM32.GPIO;
with HAL.GPIO;
with STM32.Device;



package STM32F7_Disco.Digital_IO is

   subtype GPIO_Point is STM32.GPIO.GPIO_Point;

   type Pin_Mode is (Input, Output);

   --  PINS  --
   --  CN14  --
   Pin_A0 : GPIO_Point renames STM32.Device.PA6;
   Pin_A1 : GPIO_Point renames STM32.Device.PA4;
   Pin_A2 : GPIO_Point renames STM32.Device.PC2;
   Pin_A3 : GPIO_Point renames STM32.Device.PF10;
   Pin_A4 : GPIO_Point renames STM32.Device.PF8;
   Pin_A5 : GPIO_Point renames STM32.Device.PF9;
   --  CN113  --
   Pin_D0 : GPIO_Point renames STM32.Device.PC7;
   Pin_D1 : GPIO_Point renames STM32.Device.PC6;
   Pin_D2 : GPIO_Point renames STM32.Device.PJ1;
   Pin_D3 : GPIO_Point renames STM32.Device.PF6;
   Pin_D4 : GPIO_Point renames STM32.Device.PJ0;
   Pin_D5 : GPIO_Point renames STM32.Device.PC8;
   Pin_D6 : GPIO_Point renames STM32.Device.PF7;
   Pin_D7 : GPIO_Point renames STM32.Device.PJ3;
   --  CN9  --
   Pin_D8  : GPIO_Point renames STM32.Device.PJ4;
   Pin_D9  : GPIO_Point renames STM32.Device.PH6;
   Pin_D10 : GPIO_Point renames STM32.Device.PA11;
   Pin_D11 : GPIO_Point renames STM32.Device.PB15;
   Pin_D12 : GPIO_Point renames STM32.Device.PB14;
   Pin_D13 : GPIO_Point renames STM32.Device.PA12;
   Pin_D14 : GPIO_Point renames STM32.Device.PB9;
   Pin_D15 : GPIO_Point renames STM32.Device.PB8;

   procedure Configure_Pin (Pin : GPIO_Point; Mode : Pin_Mode);

   function Digital_Read (Pin : GPIO_Point) return Boolean;

   procedure Digital_Write (Pin : GPIO_Point; Value : Boolean);

   procedure Toogle_Pin (Pin : GPIO_Point);

end STM32F7_Disco.Digital_IO;

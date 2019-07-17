with STM32f7_Disco.Digital_IO;
with Ada.Real_Time;                     use Ada.Real_Time;

procedure Main_Digital_IO_Example is
   Count : Integer := 100;
begin
   -- Switch
   STM32f7_Disco.Digital_IO.Configure_Pin(Pin  => STM32f7_Disco.Digital_IO.Pin_D0 ,
					  Mode => STM32f7_Disco.Digital_IO.Input );
   -- Red Led
   STM32f7_Disco.Digital_IO.Configure_Pin(Pin  => STM32f7_Disco.Digital_IO.Pin_D1 ,
					  Mode => STM32f7_Disco.Digital_IO.Output);
   -- Green Led
   STM32f7_Disco.Digital_IO.Configure_Pin(Pin  => STM32f7_Disco.Digital_IO.Pin_D2 ,
					  Mode => STM32f7_Disco.Digital_IO.Output);
   -- turn on Green Led
   STM32f7_Disco.Digital_IO.Digital_Write(Pin   => STM32f7_Disco.Digital_IO.Pin_D2,
					  Value => True);
   loop
      -- If the switch state changes the leds toogle
      if(STM32F7_Disco.Digital_IO.Digital_Read(Pin => STM32f7_Disco.Digital_IO.Pin_D0 )) then
	 STM32F7_Disco.Digital_IO.Toogle_Pin(Pin    => STM32f7_Disco.Digital_IO.Pin_D1);
	 STM32F7_Disco.Digital_IO.Toogle_Pin(Pin    => STM32f7_Disco.Digital_IO.Pin_D2);
	 Count:= Count -1;
      end if;
      delay until Ada.Real_Time.Clock + To_Time_Span(1.0);
      exit when Count = 0;
   end loop;
end Main_Digital_IO_Example;

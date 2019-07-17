with STM32F7_Disco.Digital_IO;
with Ada.Real_Time;   use Ada.Real_Time;

procedure Main_Servo_Test is
begin
   --  Servomotor
   STM32F7_Disco.Digital_IO.Configure_Pin (Pin  => STM32F7_Disco.Digital_IO.Pin_D3,
                                           Mode => STM32F7_Disco.Digital_IO.Output);
   loop

      --    -45 Degrees
      for I  in 1 .. 50 loop
         STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D3, Value => True);
         delay until Ada.Real_Time.Clock + To_Time_Span (0.000_75);
         STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D3, Value => False);
         delay until Ada.Real_Time.Clock + To_Time_Span (0.018_25);
      end loop;
         delay until Ada.Real_Time.Clock + To_Time_Span (1.0);

      --  +45 Degrees
      for I  in 1 .. 50 loop
         STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D3, Value => True);
         delay until Ada.Real_Time.Clock + To_Time_Span (0.001_200);
         STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D3, Value => False);
         delay until Ada.Real_Time.Clock + To_Time_Span (0.018_8);
      end loop;
         delay until Ada.Real_Time.Clock + To_Time_Span (1.0);

   end loop;


end Main_Servo_Test;

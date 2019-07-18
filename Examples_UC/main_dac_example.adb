

with STM32F7_Disco.DAC;
with Ada.Real_Time;  use Ada.Real_Time;
with Last_Chance_Handler;      pragma Unreferenced (Last_Chance_Handler);

procedure Main_DAC_Example is

begin
   STM32F7_Disco.DAC.Initilize_DAC_PA4;

   STM32F7_Disco.DAC.Set_Value_DAC_PA4 (1_047_483_607);
   delay until Ada.Real_Time.Clock + To_Time_Span (10.0);


end Main_DAC_Example;
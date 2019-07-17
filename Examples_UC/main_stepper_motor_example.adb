with STM32f7_Disco.Stepper_Motor;
with STM32F7_Disco.Digital_IO;

procedure Main_Stepper_Motor_Example is

   M1 : STM32f7_Disco.Stepper_Motor.Motor;

   Delay_1 : constant Duration :=0.005;
   --     Delay_2 : constant Duration :=0.10;
   Count_0 : Integer ;


begin

   M1.Rotation := STM32f7_Disco.Stepper_Motor.Counterclockwise;
   M1.Last_Coil_Excited :=0;
   M1.Coils(0):=STM32F7_Disco.Digital_IO.Pin_A0;
   M1.Coils(1):=STM32F7_Disco.Digital_IO.Pin_A1;
   M1.Coils(2):=STM32F7_Disco.Digital_IO.Pin_A2;
   M1.Coils(3):=STM32F7_Disco.Digital_IO.Pin_A3;

   STM32f7_Disco.Stepper_Motor.Initialize_Motor(M => M1);



   loop
      STM32f7_Disco.Stepper_Motor.Change_Rotation(M => M1);
      Count_0:= 10;
      loop
	 STM32f7_Disco.Stepper_Motor.Move_One_Step(M   => M1, Lag => Delay_1);
	 Count_0 := Count_0 -1;

	 exit when Count_0 = 0 ;
      end loop;

      STM32f7_Disco.Stepper_Motor.Change_Rotation(M => M1);
      Count_0:= 10;
      loop
	 STM32f7_Disco.Stepper_Motor.Move_One_Step(M   => M1, Lag => Delay_1);
	 Count_0 := Count_0 -1;

	 exit when Count_0 = 0 ;
      end loop;
      STM32f7_Disco.Stepper_Motor.Power_Off(M => M1);

      delay 5.0;

      STM32f7_Disco.Stepper_Motor.Move_N_Steps(M         => M1,
					       Num_Steps => 100,
					       Lag       => Delay_1);
            delay 5.0;
   end loop;

end Main_Stepper_Motor_Example;

with STM32F7_Disco.Digital_IO;

package STM32f7_Disco.Stepper_Motor is

   type Rotation_Direction is (Counterclockwise , Clockwise);
   type Num_Coils is range 0 .. 3;

   type Coils_Array is array (Num_Coils) of STM32F7_Disco.Digital_IO.GPIO_Point;

   type Motor is  record
      Rotation : Rotation_Direction;
      Coils : STM32f7_Disco.Stepper_Motor.Coils_Array;
      Last_Coil_Excited : Num_Coils;
      Running : Boolean; --first time turn or not
   end record;

   procedure Initialize_Motor(M : Motor );

   procedure Change_Rotation(M :in out Motor);

   procedure Move_One_Step(M :in Out Motor; Lag : Duration);

   procedure Move_N_Steps(M :in out Motor;Num_Steps : Natural; Lag : Duration);

   --this procedure prevents the coils from burning
   procedure Power_Off (M :in out Motor);

end STM32f7_Disco.Stepper_Motor;

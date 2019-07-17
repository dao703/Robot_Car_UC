package body STM32f7_Disco.Stepper_Motor is

   ----------------------------------------------------
   --  Initialize the stepper motor
   ----------------------------------------------------
   procedure Initialize_Motor(M : Motor ) is
   begin

      STM32f7_Disco.Digital_IO.Configure_Pin(Pin  => M.Coils(0),
					     Mode => STM32f7_Disco.Digital_IO.Output);
      STM32f7_Disco.Digital_IO.Configure_Pin(Pin  => M.Coils(1),
					     Mode => STM32f7_Disco.Digital_IO.Output);
      STM32f7_Disco.Digital_IO.Configure_Pin(Pin  => M.Coils(2),
					     Mode => STM32f7_Disco.Digital_IO.Output);
      STM32f7_Disco.Digital_IO.Configure_Pin(Pin  => M.Coils(3),
					     Mode => STM32f7_Disco.Digital_IO.Output);

      STM32f7_Disco.Digital_IO.Digital_Write(Pin => M.Coils(0),Value => False);
      STM32f7_Disco.Digital_IO.Digital_Write(Pin => M.Coils(1),Value => False);
      STM32f7_Disco.Digital_IO.Digital_Write(Pin => M.Coils(2),Value => False);
      STM32f7_Disco.Digital_IO.Digital_Write(Pin => M.Coils(3),Value => False);

   end;

   procedure Change_Rotation (M : in out Motor) is
   begin
      if M.Rotation = Clockwise then
	 M.Rotation := Counterclockwise;
      else
	 M.Rotation := Clockwise;
      end if;
   end Change_Rotation;

   procedure Move_One_Step(M : in out Motor ; Lag : Duration) is
      Count : Integer := 4;
   begin
      --prepares the motor for one step
      loop
	 if not M.Running then
	    STM32F7_Disco.Digital_IO.Toogle_Pin(Pin => M.Coils(M.Last_Coil_Excited));
	    M.Running := True;
	    delay Lag;
	 end if;

	 STM32F7_Disco.Digital_IO.Toogle_Pin(Pin => M.Coils(M.Last_Coil_Excited));
	 if M.Rotation = Clockwise then
	    M.Last_Coil_Excited := ( M.Last_Coil_Excited + 1 ) mod 4 ;
	 else
	    M.Last_Coil_Excited := ( M.Last_Coil_Excited - 1 ) mod 4 ;
	 end if;
	 STM32F7_Disco.Digital_IO.Toogle_Pin(Pin => M.Coils(M.Last_Coil_Excited));
	 delay Lag;
	 Count := Count -1;
	 exit when Count = 0;
      end loop;

   end Move_One_Step;

   procedure Move_N_Steps (M : in out Motor; Num_Steps : Natural; Lag : Duration) is
      Steps_Last  :Natural := Num_Steps;
   begin
      loop
	 Move_One_Step(M, Lag);
	 delay Lag;
	 Steps_Last := Steps_Last - 1;
	 exit when Steps_Last = 0 ;
      end loop;
   end Move_N_Steps;

   procedure Power_Off (M : in out Motor) is
   begin
      STM32F7_Disco.Digital_IO.Toogle_Pin(Pin => M.Coils(M.Last_Coil_Excited));
      M.Last_Coil_Excited:= 0;
      M.Running:= False;
   end Power_Off;

end STM32f7_Disco.Stepper_Motor;

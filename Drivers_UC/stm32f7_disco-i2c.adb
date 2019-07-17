with STM32.Setup;


package body STM32F7_Disco.I2c is

   function Is_Configured return Boolean is
   begin
      return  STM32.I2C.Port_Enabled (I2C_Port);
   end Is_Configured;


   function Is_Port_Enabled return Boolean is
   begin
      return  STM32.I2C.Port_Enabled (I2C_Port);
   end Is_Port_Enabled;


   procedure Begin_Transmision (Clock_Speed : UInt32 := 100_000) is
   begin
      STM32.Setup.Setup_I2C_Master (Port        => I2C_Port,
                                   SDA         => I2C_SDA,
                                   SCL         => I2C_SCL,
                                   SDA_AF      => I2C_SDA_AF,
                                   SCL_AF      => I2C_SCL_AF,
                                   Clock_Speed => Clock_Speed);
   end Begin_Transmision;

   procedure Write (Direction : HAL.I2C.I2C_Address; Intput_Data : HAL.I2C.I2C_Data) is
   begin
      STM32.I2C.Master_Transmit (This    => I2C_Port,
                                Addr    => Direction,
                                Data    => Intput_Data,
                                Status  => I2c_Actual_Status,
                                Timeout => Time_Out);
   end Write;

   procedure Read (Direction : HAL.I2C.I2C_Address; Output_Data : out HAL.I2C.I2C_Data) is
   begin
      STM32.I2C.Master_Receive (This    =>  I2C_Port,
                               Addr    =>  Direction,
                               Data    =>  Output_Data,
                               Status  =>  I2c_Actual_Status,
                               Timeout =>  Time_Out);
   end Read;

   function Get_Status return I2C_Status is
   begin
      return I2c_Actual_Status;
   end Get_Status;

end STM32F7_Disco.I2c;

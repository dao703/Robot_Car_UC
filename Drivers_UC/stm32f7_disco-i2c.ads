with HAL.GPIO;
with STM32.Board;           use STM32.Board;
with STM32.GPIO;  -- Set_mode procedure => enable gpio_in
with HAL.Bitmap;            use HAL.Bitmap;

with HAL;  --  uint16
with HAL.I2C;
with STM32.I2C; --  i2c protocol
with STM32.Device;
use HAL;
with Interfaces;
use type Interfaces.Unsigned_16;


package STM32F7_Disco.I2c is

   I2C_Port  : STM32.I2C.I2C_Port renames STM32.Device.I2C_1;
   I2C_SDA    : STM32.GPIO.GPIO_Point renames STM32.Board.I2C1_SDA;
   I2C_SCL    : STM32.GPIO.GPIO_Point renames STM32.Board.I2C1_SCL;
   I2C_SDA_AF : STM32.GPIO_Alternate_Function renames STM32.Device.GPIO_AF_I2C1_4;
   I2C_SCL_AF : STM32.GPIO_Alternate_Function renames STM32.Device.GPIO_AF_I2C1_4;
   Time_Out : Natural := 1_000;

   subtype Data_IO is HAL.I2C.I2C_Data;
   subtype I2C_Dir is HAL.I2C.I2C_Address;
   subtype I2C_Status is HAL.I2C.I2C_Status;

   function Is_Port_Enabled return Boolean;

   function Is_Configured return Boolean;

   procedure Begin_Transmision (Clock_Speed : UInt32 := 100_000);

   procedure Write (Direction : HAL.I2C.I2C_Address; Intput_Data : HAL.I2C.I2C_Data);

   procedure Read (Direction : HAL.I2C.I2C_Address; Output_Data : out HAL.I2C.I2C_Data);

   function  Get_Status return I2C_Status;

private I2c_Actual_Status : I2C_Status;


end STM32F7_Disco.I2c;

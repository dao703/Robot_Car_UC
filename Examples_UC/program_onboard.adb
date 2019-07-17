with  STM32F7_Disco.Digital_IO;
with STM32F7_Disco.Ethernet_Comunication;
with  Ada.Real_Time;   use Ada.Real_Time;
with STM32F7_Disco.I2c;
with Interfaces;

with Ada.Real_Time;     use Ada.Real_Time;
with HAL; use HAL;
with STM32.Board; use STM32.Board;
with HAL.Bitmap;     use HAL.Bitmap;
with LCD_Std_Out; use LCD_Std_Out;
with BMP_Fonts; use BMP_Fonts;
use type Interfaces.Unsigned_16;

with STM32F7_Disco.ADC;  --  ADC Library

with Last_Chance_Handler;  pragma Unreferenced (Last_Chance_Handler);
with Net;
with Net.Interfaces;
with Net.Headers;
with Net.Buffers;
with Net.Interfaces.STM32;


procedure Program_Onboard is


   Estado : STM32F7_Disco.I2c.I2C_Status;
   pragma Unreferenced (Estado);

   --  array de tamaño DESconocido de valores entre 0 y 255 -- 8 bits 2#00000000#
   Dato_Recibido : STM32F7_Disco.I2c.Data_IO := (0, 0);

   --  Comando de medicion continua 'D' --> 68 --> 01000100
   Dato_Enviado : constant STM32F7_Disco.I2c.Data_IO := (2, 0);

   --  Direccion Lidar 0x60 --> 2#1_100_000# --> 2#11_000_000#
   Dir_Brujula : constant STM32F7_Disco.I2c.I2C_Dir := 2#11_000_000#;


   Ifnet     : aliased Net.Interfaces.STM32.STM32_Ifnet;
   Ether  : Net.Headers.Ether_Header_Access;
   Buf    : Net.Buffers.Buffer_Type;
   Direction_Source : constant Net.Ether_Addr := (0, 16#81#, 16#E1#, 5, 5, 0);
   Direction_Mac : constant Net.Ether_Addr := (0, 16#81#, 16#E1#, 5, 5, 1);
   Direction_Destination : constant Net.Ether_Addr := (0, 16#81#, 16#E1#, 5, 5, 2);
   Logger_Protocol : constant Net.Uint16 := 16#1010#;
   Packet  : Net.Buffers.Buffer_Type;

   Message_Information : STM32F7_Disco.Ethernet_Comunication.Message_Type;
   Message_Movement : STM32F7_Disco.Ethernet_Comunication.Message_Type;
   Flag_Send : Boolean := False;

   Orientacion : Interfaces.Unsigned_16;


   BG : constant HAL.Bitmap.Bitmap_Color := (Alpha => 255, others => 64);

   --  Debug variables
   Aux_Integer : Integer := 0;
   Num_Messages : Integer := 0;

   Left_Distance : UInt16;
   Right_Distance : UInt16;

   procedure Start;
   function Get_Distance return UInt16;
   function Get_Orientation return Interfaces.Unsigned_16;
   procedure Update_Next_Move (Message : STM32F7_Disco.Ethernet_Comunication.Message_Type);

   --------------------------------
   --  Start the tasks
   --------------------------------
   procedure Start is
   begin
      --  Initialize LCD
      Display.Initialize;
      Display.Initialize_Layer (1, ARGB_8888);
      LCD_Std_Out.Set_Font (BMP_Fonts.Font16x24);
      LCD_Std_Out.Current_Background_Color := BG;
      --  Motors on the right
      STM32F7_Disco.Digital_IO.Configure_Pin (Pin  => STM32F7_Disco.Digital_IO.Pin_D11,
                                              Mode => STM32F7_Disco.Digital_IO.Output);
      STM32F7_Disco.Digital_IO.Configure_Pin (Pin  => STM32F7_Disco.Digital_IO.Pin_D9,
                                              Mode => STM32F7_Disco.Digital_IO.Output);
      --  Motors on the left
      STM32F7_Disco.Digital_IO.Configure_Pin (Pin  => STM32F7_Disco.Digital_IO.Pin_D7,
                                              Mode => STM32F7_Disco.Digital_IO.Output);
      STM32F7_Disco.Digital_IO.Configure_Pin (Pin  => STM32F7_Disco.Digital_IO.Pin_D8,
                                              Mode => STM32F7_Disco.Digital_IO.Output);
      --  Activate the motors at maximum power
      STM32F7_Disco.Digital_IO.Configure_Pin (Pin  => STM32F7_Disco.Digital_IO.Pin_D6,
                                              Mode => STM32F7_Disco.Digital_IO.Output);
      STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D6,
                                              Value => True);
      STM32F7_Disco.Digital_IO.Configure_Pin (Pin  => STM32F7_Disco.Digital_IO.Pin_D5,
                                              Mode => STM32F7_Disco.Digital_IO.Output);
      STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D5,
                                              Value => True);
      --  Servomotor
      STM32F7_Disco.Digital_IO.Configure_Pin (Pin  => STM32F7_Disco.Digital_IO.Pin_D3,
                                              Mode => STM32F7_Disco.Digital_IO.Output);
      --  Configure ADC
      STM32F7_Disco.ADC.Configure_ADC_1_Channel_6;

      --  Initialize I2C
      STM32F7_Disco.I2c.Begin_Transmision (100_000);

      --  initialize ethernet
      STM32F7_Disco.Ethernet_Comunication.Initialize (Ifnet         => Ifnet,
                                                      Direction_MAC => Direction_Mac);
   end Start;


   function Get_Distance return UInt16 is
   begin
      STM32F7_Disco.ADC.Start_Conversion_ADC_1_Channel_6; --  adc instruction
      return STM32F7_Disco.ADC.Get_Value_ADC_1_Channel_6; --  adc value
   end Get_Distance;

   function Get_Orientation return Interfaces.Unsigned_16 is
   begin
      STM32F7_Disco.I2c.Write (Dir_Brujula, Dato_Enviado);
      STM32F7_Disco.I2c.Read (Dir_Brujula, Dato_Recibido);

      Estado := STM32F7_Disco.I2c.Get_Status;
      Orientacion := Interfaces.Unsigned_16 (Dato_Recibido (0));
      Orientacion := Interfaces.Shift_Left  (Orientacion, 8);
      Orientacion := (Orientacion + Interfaces.Unsigned_16 (Dato_Recibido (1)));
      Orientacion := Orientacion / 10;

      return Interfaces.Unsigned_16 (Orientacion);
   end Get_Orientation;

   procedure Update_Next_Move (Message : STM32F7_Disco.Ethernet_Comunication.Message_Type) is
   begin
      case Message (20) is
      when '1' =>
         STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D11,
                                                 Value => True);
         STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D9,
                                                 Value => False);
         STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D7,
                                                 Value => True);
         STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D8,
                                                 Value => False);
         LCD_Std_Out.Put (X   => 50, Y   => 75, Msg => "Adelante");
      when '2' =>
         STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D11,
                                                 Value => False);
         STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D9,
                                                 Value => False);
         STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D7,
                                                 Value => True);
         STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D8,
                                                 Value => False);
         LCD_Std_Out.Put (X   => 50, Y   => 75, Msg => "Derecha");
      when '3' =>
         STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D11,
                                                 Value => False);
         STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D9,
                                                 Value => True);
         STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D7,
                                                 Value => False);
         STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D8,
                                                 Value => True);
         LCD_Std_Out.Put (X   => 50, Y   => 75, Msg => "Atras");
      when '4' =>
         STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D11,
                                                 Value => True);
         STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D9,
                                                 Value => False);
         STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D7,
                                                 Value => False);
         STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D8,
                                                 Value => False);
         LCD_Std_Out.Put (X   => 50, Y   => 75, Msg => "Izquierda");
      when others =>         --  Stay
         STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D11,
                                                 Value => False);
         STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D9,
                                                 Value => False);
         STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D7,
                                                 Value => False);
         STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D8,
                                                 Value => False);
         LCD_Std_Out.Put (X   => 50, Y   => 75, Msg => "Quieto");
      end case;
   end Update_Next_Move;


begin
   Start;
   LCD_Std_Out.Put (X   => 2, Y   => 2, Msg => "Empieza Program_Onboard");
   loop

      Message_Movement :=  STM32F7_Disco.Ethernet_Comunication.Get_Message (Ifnet  => Ifnet, Packet => Packet);
      Update_Next_Move (Message_Movement);

      Aux_Integer := Aux_Integer + 1 ;
         LCD_Std_Out.Put (X   => 50, Y   => 2, Msg => Aux_Integer'Img);

      --    -45 Degrees
      for I  in 1 .. 50 loop
         STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D3, Value => True);
         delay until Ada.Real_Time.Clock + To_Time_Span (0.000_75);
         STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D3, Value => False);
         delay until Ada.Real_Time.Clock + To_Time_Span (0.018_25);
      end loop;
      --  Get distance to objects on de left
      --  Left_Distance := Get_Distance;
      --  LCD_Std_Out.Put (X   => 50, Y   => 75, Msg => Left_Distance'Img);
      --  +45 Degrees
      for I  in 1 .. 50 loop
         STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D3, Value => True);
         delay until Ada.Real_Time.Clock + To_Time_Span (0.001_200);
         STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D3, Value => False);
         delay until Ada.Real_Time.Clock + To_Time_Span (0.018_8);
      end loop;

--        Right_Distance := Get_Distance;
--        LCD_Std_Out.Put (X   => 50, Y   => 75, Msg => Right_Distance'Img);
--
--        Orientacion := Get_Orientation;
--        LCD_Std_Out.Put (X   => 50, Y   => 75, Msg => Orientacion'Img);


      delay until Clock +  To_Time_Span (0.1);
   end loop;
end Program_Onboard;

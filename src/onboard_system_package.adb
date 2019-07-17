with  STM32F7_Disco.Digital_IO;  --  Digital IO Library
with STM32F7_Disco.Ethernet_Comunication;  -- Ethernet Library
with STM32F7_Disco.I2c;  -- I2C Library
with STM32F7_Disco.ADC;  --  ADC Library

with Interfaces;

with HAL;                           use HAL;
with STM32.Board;                   use STM32.Board;
with HAL.Bitmap;                    use HAL.Bitmap;
with LCD_Std_Out;                   use LCD_Std_Out;
with BMP_Fonts;                     use BMP_Fonts;

with Ada.Synchronous_Task_Control;

with Net;
with Net.Interfaces;
with Net.Headers;
with Net.Buffers;
with Net.Interfaces.STM32;

use type Interfaces.Unsigned_16;
with  Ada.Real_Time;   use Ada.Real_Time;

--  with Last_Chance_Handler;  pragma Unreferenced (Last_Chance_Handler);

package body Onboard_System_Package is

   Estado : STM32F7_Disco.I2c.I2C_Status;
   pragma Unreferenced (Estado);

   Data_Receive : STM32F7_Disco.I2c.Data_IO := (0, 0);

   Data_Send : constant STM32F7_Disco.I2c.Data_IO := (2, 0);

   Dir_Compass : constant STM32F7_Disco.I2c.I2C_Dir := 2#11_000_000#;

   --  ethernet variables
   Ifnet     : aliased Net.Interfaces.STM32.STM32_Ifnet;
   Ether  : Net.Headers.Ether_Header_Access;
   Buf    : Net.Buffers.Buffer_Type;
   Destination_Address : constant Net.Ether_Addr := (0, 16#81#, 16#E1#, 5, 5, 0);
   Source_Address : constant Net.Ether_Addr      := (0, 16#81#, 16#E1#, 5, 5, 1);
   Logger_Protocol : constant Net.Uint16 := 16#1010#;
   Packet  : Net.Buffers.Buffer_Type;
   Send_Message : STM32F7_Disco.Ethernet_Comunication.Message_Type;
   Receive_Message : STM32F7_Disco.Ethernet_Comunication.Message_Type;
   Flag_Send : Boolean := False;

   --  flag to start
   Ready : Ada.Synchronous_Task_Control.Suspension_Object;

   --  background color of the screen
   BG : constant HAL.Bitmap.Bitmap_Color := (Alpha => 255, others => 64);

   --  Debug variables
   Aux_Integer : Integer := 0;
   Num_Messages : Integer := 0;
   pragma Unreferenced (Num_Messages);

   function Get_Distance return UInt16;
   function Get_Orientation return Integer;
   procedure Update_Next_Move (Message : STM32F7_Disco.Ethernet_Comunication.Message_Type);
   function Get_Message_Information return STM32F7_Disco.Ethernet_Comunication.Message_Type;

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
                                                      Mac_Src => Source_Address);

      --  Send the firts null message to initialize the board
      Flag_Send :=  STM32F7_Disco.Ethernet_Comunication.Send_Message (Buffer        => Buf,
                                                                      Ifnet         => Ifnet,
                                                                      Ether         => Ether,
                                                                      Mac_Src        => Source_Address,
                                                                      Mac_Dst        => Destination_Address,
                                                                      Protocol      => Logger_Protocol,
                                                                      Message       => "99999999999999999999999999999999999999999999999999");

      --  Move Task can start
      Ada.Synchronous_Task_Control.Set_True (Ready);

   end Start;


   function Get_Distance return UInt16 is
   begin
      STM32F7_Disco.ADC.Start_Conversion_ADC_1_Channel_6; --  adc instruction
      return STM32F7_Disco.ADC.Get_Value_ADC_1_Channel_6; --  adc value
   end Get_Distance;

   function Get_Orientation return Integer is
      Orientation : Interfaces.Unsigned_16;
   begin
      STM32F7_Disco.I2c.Write (Dir_Compass, Data_Send);
      STM32F7_Disco.I2c.Read (Dir_Compass, Data_Receive);

      Estado := STM32F7_Disco.I2c.Get_Status;
      Orientation := Interfaces.Unsigned_16 (Data_Receive (0));
      Orientation := Interfaces.Shift_Left  (Orientation, 8);
      Orientation := (Orientation + Interfaces.Unsigned_16 (Data_Receive (1)));
      Orientation := Orientation / 10;

      return Integer (Orientation);
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
         delay until Ada.Real_Time.Clock + To_Time_Span (1.0);
         LCD_Std_Out.Put (X   => 50, Y   => 75, Msg => "1 --> Adelante ");

      when '2' =>
         STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D11,
                                                 Value => False);
         STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D9,
                                                 Value => False);
         STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D7,
                                                 Value => True);
         STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D8,
                                                 Value => False);
         LCD_Std_Out.Put (X   => 50, Y   => 75, Msg => "2 --> Derecha  ");

      when '3' =>
         STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D11,
                                                 Value => False);
         STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D9,
                                                 Value => True);
         STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D7,
                                                 Value => False);
         STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D8,
                                                 Value => True);
         LCD_Std_Out.Put (X   => 50, Y   => 75, Msg => "3 --> Atras    ");
      when '4' =>
         STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D11,
                                                 Value => True);
         STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D9,
                                                 Value => False);
         STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D7,
                                                 Value => False);
         STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D8,
                                                 Value => False);
         LCD_Std_Out.Put (X   => 50, Y   => 75, Msg => "4 --> Izquierda");

      when others =>
         --  the car stays still
         STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D11,
                                                 Value => False);
         STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D9,
                                                 Value => False);
         STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D7,
                                                 Value => False);
         STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D8,
                                                 Value => False);
         LCD_Std_Out.Put (X   => 50, Y   => 75, Msg => "0 --> Quieto   ");
      end case;

      delay until Ada.Real_Time.Clock + To_Time_Span (0.3);

      --  the car stays still
      STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D11,
                                              Value => False);
      STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D9,
                                              Value => False);
      STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D7,
                                              Value => False);
      STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D8,
                                              Value => False);
      LCD_Std_Out.Put (X   => 50, Y   => 75, Msg => "0 --> Quieto   ");

   end Update_Next_Move;


   function Get_Message_Information return STM32F7_Disco.Ethernet_Comunication.Message_Type is
      Aux_Message : STM32F7_Disco.Ethernet_Comunication.Message_Type;
      --  Orientation : Integer;
      Left_Distance : UInt16;
      Right_Distance : UInt16;

   begin
      --  -45 Degrees
      for I  in 1 .. 50 loop
         STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D3, Value => True);
         delay until Ada.Real_Time.Clock + To_Time_Span (0.000_75);
         STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D3, Value => False);
         delay until Ada.Real_Time.Clock + To_Time_Span (0.018_25);
      end loop;
      --  Get Distance To Objects on the Left
      Left_Distance := Get_Distance;
      if (Left_Distance > 2000) then
         Aux_Message (1) := '1';
      elsif Left_Distance > 1750 then
         Aux_Message (1) := '2';
      else
         Aux_Message (1) := '3';
      end if;
      --  fill the part of the message
      for I in 2 .. 15 loop
         Aux_Message (I) := Aux_Message (1);
      end loop;
      LCD_Std_Out.Put (X => 1, Y => 200, Msg => "Left distance -->" & Left_Distance'Img);

      --  +45 Degrees
      for I  in 1 .. 50 loop
         STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D3, Value => True);
         delay until Ada.Real_Time.Clock + To_Time_Span (0.001_200);
         STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D3, Value => False);
         delay until Ada.Real_Time.Clock + To_Time_Span (0.018_8);
      end loop;
      Right_Distance := Get_Distance;
      if (Right_Distance > 2000) then
         Aux_Message (16) := '1';
      elsif Right_Distance > 1750 then
         Aux_Message (16) := '2';
      else
         Aux_Message (16) := '3';
      end if;
      --  fill the part of the message
      for I in 17 .. 30 loop
         Aux_Message (I) := Aux_Message (16);
      end loop;
      LCD_Std_Out.Put (X => 1, Y => 225, Msg => "Right distance -->" & Right_Distance'Img);

      --        Orientation := Get_Orientation;
      --        if (Orientation > 340 and Orientation < 25) then
      --           Aux_Message (31) := '1';
      --        elsif (Orientation > 25 and Orientation < 70) then
      --           Aux_Message (31) := '2';
      --        elsif (Orientation > 70 and Orientation < 115) then
      --           Aux_Message (31) := '3';
      --        elsif (Orientation > 115 and Orientation < 160) then
      --           Aux_Message (31) := '4';
      --        elsif (Orientation > 160 and Orientation < 205) then
      --           Aux_Message (31) := '5';
      --        elsif (Orientation > 205 and Orientation < 250) then
      --           Aux_Message (31) := '6';
      --        elsif (Orientation > 250 and Orientation < 295) then
      --           Aux_Message (31) := '7';
      --        else
      --           Aux_Message (31) := '8';
      --        end if;
      --        LCD_Std_Out.Put (X => 1, Y => 250, Msg => "Orientation -->" & Orientation'Img);

      --  Orientation example
      Aux_Message (31) := '8';
      for I in 32 .. 50 loop
         Aux_Message (I) := Aux_Message (31);
      end loop;

      LCD_Std_Out.Put (0, 200, "fist 25 " & Aux_Message (1 .. 25));
      LCD_Std_Out.Put (0, 225, "Second 25 " & Aux_Message (26 .. 50));

      --  Message example
      --  Aux_Message := "33333333333333311111111111111155555555555555555555";
      return Aux_Message;
   end Get_Message_Information;

   -------------------------------------------------------------------------------------------------------------------
   -- Main task. This task receive the next move to do and send the information to the remote control board.        --
   -- It doesn't have delay because it wait to receive new message with the movement.                               --
   -------------------------------------------------------------------------------------------------------------------
   task body Onborad_Task is
   begin

      Ada.Synchronous_Task_Control.Suspend_Until_True (Ready);
      --  LCD_Std_Out.Put (X => 1, Y => 1, Msg => "tarea activa ");

      loop
         --  LCD_Std_Out.Put (X => 1, Y => 25, Msg => "a la esperea de recibir un movimiento");
         --  Receive movement
         Receive_Message :=  STM32F7_Disco.Ethernet_Comunication.Get_Message (Ifnet  => Ifnet, Packet => Packet);
         Update_Next_Move (Receive_Message);
         --  send the actual information
         Send_Message := Get_Message_Information;
         Flag_Send :=  STM32F7_Disco.Ethernet_Comunication.Send_Message (Buffer        => Buf,
                                                                         Ifnet         => Ifnet,
                                                                         Ether         => Ether,
                                                                         Mac_Src        => Source_Address,
                                                                         Mac_Dst        => Destination_Address,
                                                                         Protocol      => Logger_Protocol,
                                                                         Message       => Send_Message);
         --           if Flag_Send then
         --              Num_Messages := Num_Messages + 1;
         --              -- LCD_Std_Out.Put (X => 1, Y => 50, Msg => "Mensaje " & Num_Messages'Img & " enviado");
         --           end if;

      end loop;

   end Onborad_Task;

end Onboard_System_Package;

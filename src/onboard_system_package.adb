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

   Analog_Mode   : STM32.GPIO.GPIO_Port_Configuration := (Mode => STM32.GPIO.Mode_Analog,
                                                          Output_Type  => STM32.GPIO.Push_Pull, 
                                                          Speed       => STM32.GPIO.Speed_2MHz, 
                                                          Resistors   => STM32.GPIO.Floating);

   function Get_Distance return UInt16;
   procedure Update_Next_Move (Message : STM32F7_Disco.Ethernet_Comunication.Message_Type);
   function Get_Message_Information return STM32F7_Disco.Ethernet_Comunication.Message_Type;

   --------------------------------
   --  Start the task
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

      STM32F7_Disco.Digital_IO.Configure_Pin (Pin  => STM32F7_Disco.Digital_IO.Pin_A1,
                                              Mode => STM32F7_Disco.Digital_IO.Output);
      --  Servomotor
      STM32F7_Disco.Digital_IO.Configure_Pin (Pin  => STM32F7_Disco.Digital_IO.Pin_D3,
                                              Mode => STM32F7_Disco.Digital_IO.Output);
      --  Configure ADC -->  measure the distance
      STM32F7_Disco.ADC.Configure_ADC_1_Channel_6;

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

      --  Onboard Task can start
      Ada.Synchronous_Task_Control.Set_True (Ready);
   end Start;

   function Get_Distance return UInt16 is
   begin
      STM32F7_Disco.ADC.Start_Conversion_ADC_1_Channel_6; --  adc instruction
      return STM32F7_Disco.ADC.Get_Value_ADC_1_Channel_6; --  adc value
   end Get_Distance;

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
         --  simulates pwm to regulate the speed
         for I  in 1 .. 50 loop
            STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_A1, Value => True);
            delay until Ada.Real_Time.Clock + To_Time_Span (0.005_0);
            STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_A1, Value => False);
            delay until Ada.Real_Time.Clock + To_Time_Span (0.015_0);
         end loop;
         delay until Ada.Real_Time.Clock + To_Time_Span (1.0);
      when '2' =>
         STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D11,
                                                 Value => False);
         STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D9,
                                                 Value => False);
         STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D7,
                                                 Value => True);
         STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D8,
                                                 Value => False);
         --  simulates pwm to regulate the speed
         for I  in 1 .. 50 loop
            STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_A1, Value => True);
            delay until Ada.Real_Time.Clock + To_Time_Span (0.010_0);
            STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_A1, Value => False);
            delay until Ada.Real_Time.Clock + To_Time_Span (0.010_0);
         end loop;
      when '3' =>
         STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D11,
                                                 Value => False);
         STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D9,
                                                 Value => True);
         STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D7,
                                                 Value => False);
         STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D8,
                                                 Value => True);
         --  simulates pwm to regulate the speed
         for I  in 1 .. 50 loop
            STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_A1, Value => True);
            delay until Ada.Real_Time.Clock + To_Time_Span (0.005_0);
            STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_A1, Value => False);
            delay until Ada.Real_Time.Clock + To_Time_Span (0.015_0);
         end loop;
      when '4' =>
         STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D11,
                                                 Value => True);
         STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D9,
                                                 Value => False);
         STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D7,
                                                 Value => False);
         STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D8,
                                                 Value => False);
         --  simulates pwm to regulate the speed
         for I  in 1 .. 50 loop
            STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_A1, Value => True);
            delay until Ada.Real_Time.Clock + To_Time_Span (0.010_0);
            STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_A1, Value => False);
            delay until Ada.Real_Time.Clock + To_Time_Span (0.010_0);
         end loop;
      when others =>
			null;
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
   end Update_Next_Move;

   function Get_Message_Information return STM32F7_Disco.Ethernet_Comunication.Message_Type is
      Aux_Message : STM32F7_Disco.Ethernet_Comunication.Message_Type;
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
      if (Left_Distance < 600) then
         --  very far
         Aux_Message (1) := '4';
      elsif Left_Distance >= 601 and Left_Distance < 800 then
         --  far
         Aux_Message (1) := '1';
      elsif Left_Distance >= 801 and Left_Distance < 1250 then
         --  near
         Aux_Message (1) := '2';
      else
         --very near
         Aux_Message (1) := '3';
      end if;
      --  fill the part of the message
      for I in 2 .. 15 loop
         Aux_Message (I) := Aux_Message (1);
      end loop;
      --  +45 Degrees
      for I  in 1 .. 50 loop
         STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D3, Value => True);
         delay until Ada.Real_Time.Clock + To_Time_Span (0.001_200);
         STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D3, Value => False);
         delay until Ada.Real_Time.Clock + To_Time_Span (0.018_8);
      end loop;
      Right_Distance := Get_Distance;
      if (Right_Distance < 600) then
         --  very far
         Aux_Message (1) := '4';
      elsif Right_Distance >= 601 and Right_Distance < 800 then
         --  far
         Aux_Message (1) := '1';
      elsif Right_Distance >= 801 and Right_Distance < 1250 then
         --  near
         Aux_Message (1) := '2';
      else
         --very near
         Aux_Message (1) := '3';
      end if;
      --  fill the part of the message
      for I in 17 .. 30 loop
         Aux_Message (I) := Aux_Message (16);
      end loop;
      Aux_Message (31) := '0';
      for I in 32 .. 50 loop
         Aux_Message (I) := Aux_Message (31);
      end loop;
       return Aux_Message;
   end Get_Message_Information;

   -------------------------------------------------------------------------------------------------------------------
   -- Main task. This task receive the next move to do and send the information to the remote control board.        --
   -- It doesn't have delay because it wait to receive new message with the movement.                               --
   -------------------------------------------------------------------------------------------------------------------
   task body Onborad_Task is
   begin
      Ada.Synchronous_Task_Control.Suspend_Until_True (Ready);
      loop
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
      end loop;
   end Onborad_Task;
end Onboard_System_Package;

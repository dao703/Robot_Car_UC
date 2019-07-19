with STM32F7_Disco.Ethernet_Comunication;

with STM32.Board;           use STM32.Board;
with HAL.Bitmap;            use HAL.Bitmap;
with HAL.Touch_Panel;       use HAL.Touch_Panel;
with BMP_Fonts;
with LCD_Std_Out;
with Interfaces;

use type Interfaces.Unsigned_16;

with Net; use Net;
with Net.Interfaces;
with Net.Headers;
with Net.Buffers;
with Net.Interfaces.STM32;

with STM32F7_Disco.I2c;  -- I2C Library

with Ada.Synchronous_Task_Control;

with Last_Chance_Handler;  pragma Unreferenced (Last_Chance_Handler);
with Protected_Object_Movement;     use Protected_Object_Movement;
with Ada.Real_Time;                 use Ada.Real_Time;

package body Remote_Control_Car_Tasks is
   --  background color of the screen
   BG : constant Bitmap_Color := (Alpha => 255, others => 64);

   --  I2C Variables
   Status : STM32F7_Disco.I2c.I2C_Status;
   Data_Receive : STM32F7_Disco.I2c.Data_IO := (0, 0);
   Data_Send : constant STM32F7_Disco.I2c.Data_IO := (2, 0);
   Dir_Compass : constant STM32F7_Disco.I2c.I2C_Dir := 2#11_000_000#;

   --  where the person press the screen
   Puntero : TP_Touch_State := Null_Touch_State;

   --  hmi variables
   Thickness : constant Natural := 3;
   Radius : constant Natural := 150;
   Center : constant Point := (625, 300);

   --  ethernet variables
   Ifnet     : aliased Net.Interfaces.STM32.STM32_Ifnet;
   Ether  : Net.Headers.Ether_Header_Access;
   Buf    : Net.Buffers.Buffer_Type;
   Source_Address : constant       Ether_Addr := (0, 16#81#, 16#E1#, 5, 5, 0);
   Destination_Address : constant  Ether_Addr := (0, 16#81#, 16#E1#, 5, 5, 1);
   Logger_Protocol : constant Net.Uint16 := 16#1010#;
   Packet  : Net.Buffers.Buffer_Type;
   Send_Message : STM32F7_Disco.Ethernet_Comunication.Message_Type;
   Receive_Message : STM32F7_Disco.Ethernet_Comunication.Message_Type;
   Null_Message : STM32F7_Disco.Ethernet_Comunication.Message_Type :=  "00000000000000000000000000000000000000000000000000";
   Flag_Send : Boolean := False;

   --  Barriers
   Ready : Ada.Synchronous_Task_Control.Suspension_Object;
   Ready1 : Ada.Synchronous_Task_Control.Suspension_Object;
   Ready2 : Ada.Synchronous_Task_Control.Suspension_Object;
   Ready3 : Ada.Synchronous_Task_Control.Suspension_Object;

   --  Clocks
   Clock_Check_Display : Time;

   --  Debug variables
   Aux_Integer : Integer := 0;
   Num_Messages : Integer := 0;

   --  protected object with the new movement
   Move : Movement;

   --  Functions and procedures
   procedure Clear;
   procedure Print_Controls;
   procedure Clear_Orientation;
   procedure Update_Orientation (Orientation : Character);
   procedure Update_Object_Distance (Left_Distance : Character; Right_Distance : Character);
   function Get_Message_From_Position return STM32F7_Disco.Ethernet_Comunication.Message_Type;
   --------------------------------
   --  Start the tasks
   --------------------------------
   procedure Start is
   begin
      --  Initialize touch panel
      Touch_Panel.Initialize;
      --  Initialize LCD
      Display.Initialize;
      Display.Initialize_Layer (1, ARGB_8888);
      Clear;
      Print_Controls;
      --  Initialize I2C
      STM32F7_Disco.I2c.Begin_Transmision (100_000);
      STM32F7_Disco.Ethernet_Comunication.Initialize (Ifnet   => Ifnet,
                                                      Mac_Src => Source_Address);
      Flag_Send :=  STM32F7_Disco.Ethernet_Comunication.Send_Message (Buffer        => Buf,
                                                                      Ifnet         => Ifnet,
                                                                      Ether         => Ether,
                                                                      Mac_Src        => Source_Address,
                                                                      Mac_Dst        => Destination_Address,
                                                                      Protocol      => Logger_Protocol,
                                                                      Message       => Null_Message);
      Ada.Synchronous_Task_Control.Set_True (Ready);  --  Check_Display
      Ada.Synchronous_Task_Control.Set_True (Ready1);  --  Trasnmitter_Task
      Ada.Synchronous_Task_Control.Set_True (Ready2);  --  Receiver_Task
      Ada.Synchronous_Task_Control.Set_True (Ready3);  --  Orientation_Task
   end Start;

   procedure Clear is
   begin
      Display.Hidden_Buffer (1).Set_Source (BG);
      Display.Hidden_Buffer (1).Fill;
   end Clear;

   procedure Print_Controls is
   begin
      Display.Hidden_Buffer (1).Set_Source (HAL.Bitmap.White);
      --  Up arrow
      Display.Hidden_Buffer (1).Draw_Line ((200, 25), (250, 75), Thickness);
      Display.Hidden_Buffer (1).Draw_Line ((250, 75), (225, 75), Thickness);
      Display.Hidden_Buffer (1).Draw_Line ((225, 75), (225, 150), Thickness);
      Display.Hidden_Buffer (1).Draw_Line ((225, 150), (175, 150), Thickness);
      Display.Hidden_Buffer (1).Draw_Line ((175, 150), (175, 75), Thickness);
      Display.Hidden_Buffer (1).Draw_Line ((175, 75), (150, 75), Thickness);
      Display.Hidden_Buffer (1).Draw_Line ((150, 75), (200, 25), Thickness);
      --  Down arrow 
      Display.Hidden_Buffer (1).Draw_Line ((225, 300), (225, 375), Thickness);
      Display.Hidden_Buffer (1).Draw_Line ((225, 375), (250, 375), Thickness);
      Display.Hidden_Buffer (1).Draw_Line ((250, 375), (200, 425), Thickness);
      Display.Hidden_Buffer (1).Draw_Line ((200, 425), (150, 375), Thickness);
      Display.Hidden_Buffer (1).Draw_Line ((150, 375), (175, 375), Thickness);
      Display.Hidden_Buffer (1).Draw_Line ((175, 375), (175, 300), Thickness);
      Display.Hidden_Buffer (1).Draw_Line ((175, 300), (225, 300), Thickness);
      --  Left arrow
      Display.Hidden_Buffer (1).Draw_Line ((150, 200), (150, 250), Thickness);
      Display.Hidden_Buffer (1).Draw_Line ((150, 250), (075, 250), Thickness);
      Display.Hidden_Buffer (1).Draw_Line ((075, 250), (075, 275), Thickness);
      Display.Hidden_Buffer (1).Draw_Line ((075, 275), (025, 225), Thickness);
      Display.Hidden_Buffer (1).Draw_Line ((025, 225), (075, 175), Thickness);
      Display.Hidden_Buffer (1).Draw_Line ((075, 175), (075, 200), Thickness);
      Display.Hidden_Buffer (1).Draw_Line ((075, 200), (150, 200), Thickness);
      --  Right arrow
      Display.Hidden_Buffer (1).Draw_Line ((250, 200), (325, 200), Thickness);
      Display.Hidden_Buffer (1).Draw_Line ((325, 200), (325, 175), Thickness);
      Display.Hidden_Buffer (1).Draw_Line ((325, 175), (375, 225), Thickness);
      Display.Hidden_Buffer (1).Draw_Line ((375, 225), (325, 275), Thickness);
      Display.Hidden_Buffer (1).Draw_Line ((325, 275), (325, 250), Thickness);
      Display.Hidden_Buffer (1).Draw_Line ((325, 250), (250, 250), Thickness);
      Display.Hidden_Buffer (1).Draw_Line ((250, 250), (250, 200), Thickness);
      --  Divider line
      Display.Hidden_Buffer (1).Draw_Vertical_Line ((400, 0), 480);
      Display.Hidden_Buffer (1).Draw_Vertical_Line ((401, 0), 480);
      Display.Hidden_Buffer (1).Draw_Vertical_Line ((402, 0), 480);
      --  Compass circle
      Display.Hidden_Buffer (1).Draw_Circle (Center, Radius);
      Display.Hidden_Buffer (1).Draw_Circle (Center, Radius + 1);
      Display.Hidden_Buffer (1).Draw_Circle (Center, Radius + 2);
      --  Car representation - Distance 
      Display.Hidden_Buffer (1).Cubic_Bezier (P1        => (500, 150),
                                              P2        => (600, 50),
                                              P3        => (650, 50),
                                              P4        => (750, 150),
                                              N         => 4,
                                              Thickness => Thickness);
      Display.Update_Layer (1, Copy_Back => True);
   end Print_Controls;

   procedure Clear_Orientation is
   begin
      Display.Hidden_Buffer (1).Set_Source (BG);
      Display.Hidden_Buffer (1).Fill_Circle (Center => Center, Radius => Radius);
      Display.Update_Layer (1, Copy_Back => True);
   end Clear_Orientation;

   procedure Update_Orientation (Orientation : Character)  is
   begin
      Clear_Orientation;
      Display.Hidden_Buffer (1).Set_Source (HAL.Bitmap.Green);
      case Orientation is
         when '1' =>
            --  N
            Display.Hidden_Buffer (1).Draw_Line (Center, (Center.X, Center.Y - Radius), Thickness);
            Display.Hidden_Buffer (1).Draw_Line ((Center.X, Center.Y - Radius),
                                                 (Center.X - 25, Center.Y - 125), Thickness);
            Display.Hidden_Buffer (1).Draw_Line ((Center.X, Center.Y - Radius),
                                                 (Center.X + 25, Center.Y - 125), Thickness);
         when '2' =>
            --  NE
            Display.Hidden_Buffer (1).Draw_Line (Center, (Center.X + 106, Center.Y - 106), Thickness);
            Display.Hidden_Buffer (1).Draw_Line ((Center.X + 106, Center.Y - 106),
                                                 (Center.X + 106 - 25, Center.Y - 106), Thickness);
            Display.Hidden_Buffer (1).Draw_Line ((Center.X + 106, Center.Y - 106),
                                                 (Center.X + 106, Center.Y - 106 + 25), Thickness);
         when '3' =>
            --  E
            Display.Hidden_Buffer (1).Draw_Line (Center, (Center.X + Radius, Center.Y), Thickness);
            Display.Hidden_Buffer (1).Draw_Line ((Center.X + Radius, Center.Y),
                                                 (Center.X + Radius - 25, Center.Y - 25), Thickness);
            Display.Hidden_Buffer (1).Draw_Line ((Center.X + Radius, Center.Y),
                                                 (Center.X + Radius - 25, Center.Y + 25), Thickness);
         when '4' =>
            --  SE
            Display.Hidden_Buffer (1).Draw_Line (Center, (Center.X + 106, Center.Y + 106), Thickness);
            Display.Hidden_Buffer (1).Draw_Line ((Center.X + 106, Center.Y + 106),
                                                 (Center.X + 106, Center.Y + 106 - 25), Thickness);
            Display.Hidden_Buffer (1).Draw_Line ((Center.X + 106, Center.Y + 106),
                                                 (Center.X + 106 - 25, Center.Y + 106), Thickness);
         when '5' =>
            --  S
            Display.Hidden_Buffer (1).Draw_Line (Center, (Center.X, Center.Y + Radius), Thickness);
            Display.Hidden_Buffer (1).Draw_Line ((Center.X, Center.Y + Radius),
                                                 (Center.X - 25, Center.Y + 125), Thickness);
            Display.Hidden_Buffer (1).Draw_Line ((Center.X, Center.Y + Radius),
                                                 (Center.X + 25, Center.Y + 125), Thickness);
         when '6' =>
            --  SO
            Display.Hidden_Buffer (1).Draw_Line (Center, (Center.X - 106, Center.Y + 106), Thickness);
            Display.Hidden_Buffer (1).Draw_Line ((Center.X - 106, Center.Y + 106),
                                                 (Center.X - 106, Center.Y + 106 - 25), Thickness);
            Display.Hidden_Buffer (1).Draw_Line ((Center.X - 106, Center.Y + 106),
                                                 (Center.X - 106 + 25, Center.Y + 106), Thickness);
         when '7' =>
            --  O
            Display.Hidden_Buffer (1).Draw_Line (Center, (Center.X - Radius, Center.Y), Thickness);
            Display.Hidden_Buffer (1).Draw_Line ((Center.X - Radius, Center.Y),
                                                 (Center.X - Radius + 25, Center.Y - 25), Thickness);
            Display.Hidden_Buffer (1).Draw_Line ((Center.X - Radius, Center.Y),
                                                 (Center.X - Radius + 25, Center.Y + 25), Thickness);
         when '8' =>
            --  NE
            Display.Hidden_Buffer (1).Draw_Line (Center, (Center.X - 106, Center.Y - 106), Thickness);
            Display.Hidden_Buffer (1).Draw_Line ((Center.X - 106, Center.Y - 106),
                                                 (Center.X - 106 + 25, Center.Y - 106), Thickness);
            Display.Hidden_Buffer (1).Draw_Line ((Center.X - 106, Center.Y - 106),
                                                 (Center.X - 106, Center.Y - 106 + 25), Thickness);
         when others =>
            null;
      end case;
      Display.Update_Layer (1, Copy_Back => True);
   end Update_Orientation;

   procedure Update_Object_Distance (Left_Distance : Character; Right_Distance : Character) is
   begin
      --  clear the previous distance
      Display.Hidden_Buffer (1).Set_Source (BG);
      Display.Hidden_Buffer (1).Draw_Line ((600, 40), (480, 105), Thickness);
      Display.Hidden_Buffer (1).Draw_Line ((615, 45), (490, 115), Thickness);
      Display.Hidden_Buffer (1).Draw_Line ((625, 50), (500, 125), Thickness);
      Display.Hidden_Buffer (1).Draw_Line ((640, 40), (770, 105), Thickness);
      Display.Hidden_Buffer (1).Draw_Line ((635, 45), (754, 115), Thickness);
      Display.Hidden_Buffer (1).Draw_Line ((625, 50), (750, 125), Thickness);
      --  Left sensor
      case Left_Distance is
         when '1' =>
            --  far
            Display.Hidden_Buffer (1).Set_Source (HAL.Bitmap.Yellow);
            Display.Hidden_Buffer (1).Draw_Line ((640, 40), (770, 105), Thickness);
         when '2' =>
            --  near
            Display.Hidden_Buffer (1).Set_Source (HAL.Bitmap.Orange);
            Display.Hidden_Buffer (1).Draw_Line ((635, 45), (754, 115), Thickness);
         when '3' =>
            --  very near
            Display.Hidden_Buffer (1).Set_Source (HAL.Bitmap.Red);
            Display.Hidden_Buffer (1).Draw_Line ((625, 50), (750, 125), Thickness);
         when others  =>
            null;
      end case;
      --  Right sensor
      case Right_Distance is
         when '1' =>
            --  far
            Display.Hidden_Buffer (1).Set_Source (HAL.Bitmap.Yellow);
            Display.Hidden_Buffer (1).Draw_Line ((600, 40), (480, 105), Thickness);
         when '2' =>
            --  near
            Display.Hidden_Buffer (1).Set_Source (HAL.Bitmap.Orange);
            Display.Hidden_Buffer (1).Draw_Line ((615, 45), (490, 115), Thickness);
         when '3' =>
            --  Very near
            Display.Hidden_Buffer (1).Set_Source (HAL.Bitmap.Red);
            Display.Hidden_Buffer (1).Draw_Line ((625, 50), (500, 125), Thickness);
         when others =>
            null;
      end case;

      Display.Update_Layer (1, Copy_Back => True);
   end Update_Object_Distance;

   function Get_Message_From_Position return STM32F7_Disco.Ethernet_Comunication.Message_Type is
      Aux_Message : STM32F7_Disco.Ethernet_Comunication.Message_Type;
   begin
      Puntero := Touch_Panel.Get_Touch_Point (1);
      --  Check arrow up or down
      if Puntero.X >= 150 and Puntero.X <= 250 then
         --  arrow up
         if Puntero.Y >= 25 and Puntero.Y <= 150 then
            --  LCD_Std_Out.Put (X => 500, Y => 100, Msg => "Arriba   ");
            Aux_Message := "11111111111111111111111111111111111111111111111111";
            --  arrow down
         elsif Puntero.Y >= 300 and Puntero.Y <= 425 then
            --  LCD_Std_Out.Put (X => 500, Y => 100, Msg => "Abajo    ");
            Aux_Message := "33333333333333333333333333333333333333333333333333";
         end if;

         --  Check arrow left or right
      elsif Puntero.Y >= 175 and Puntero.Y <= 275  then
         --  arrow left
         if Puntero.X >= 25 and Puntero.X <= 250 then
            --  LCD_Std_Out.Put (X => 500, Y => 100, Msg => "Izquierda");
            Aux_Message := "44444444444444444444444444444444444444444444444444";
            --  arrow right
         elsif Puntero.X >= 250 and Puntero.X <= 375 then
            --  LCD_Std_Out.Put (X => 500, Y => 100, Msg => "Derecha  ");
            Aux_Message := "22222222222222222222222222222222222222222222222222";
         end if;
      else
         --  stay still
         Aux_Message := Null_Message;
      end if;

      return Aux_Message;
   end Get_Message_From_Position;

   function Get_Orientation return Integer is
      Orientation : Interfaces.Unsigned_16;
   begin
      STM32F7_Disco.I2c.Write (Dir_Compass, Data_Send);
      STM32F7_Disco.I2c.Read (Dir_Compass, Data_Receive);
      Status := STM32F7_Disco.I2c.Get_Status;
      Orientation := Interfaces.Unsigned_16 (Data_Receive (0));
      Orientation := Interfaces.Shift_Left  (Orientation, 8);
      Orientation := (Orientation + Interfaces.Unsigned_16 (Data_Receive (1)));
      Orientation := Orientation / 10;
      return Integer (Orientation);
   end Get_Orientation;

   task body Trasnmitter_Task is
   begin
      --  Wait until the Display driver is ready.
      Ada.Synchronous_Task_Control.Suspend_Until_True (Ready1);
      loop
         --  when the user press one button, one message is sent
         Move.Get_Move (Send_Message);
         --  send the next movement
         Flag_Send :=  STM32F7_Disco.Ethernet_Comunication.Send_Message (Buffer        => Buf, Ifnet  => Ifnet,
                                                                         Ether         => Ether,
                                                                         Mac_Src        => Source_Address,
                                                                         Mac_Dst        => Destination_Address,
                                                                         Protocol      => Logger_Protocol,
                                                                         Message       => Send_Message);
      end loop;
   end Trasnmitter_Task;

   task body Receiver_Task is
      --  Num_Messages_Receives : Integer := 0;
   begin
      --  Wait until the Display driver is ready.
      Ada.Synchronous_Task_Control.Suspend_Until_True (Ready2);
      loop
         --  wait until new massage arrive
         Receive_Message := STM32F7_Disco.Ethernet_Comunication.Get_Message (Ifnet  => Ifnet, Packet => Packet);
         Update_Object_Distance (Receive_Message (7), Receive_Message (22));
      end loop;
   end Receiver_Task;

   task body Check_Display is
      Aux_Message : STM32F7_Disco.Ethernet_Comunication.Message_Type;
   begin
      Ada.Synchronous_Task_Control.Suspend_Until_True (Ready);

      Clock_Check_Display := Ada.Real_Time.Clock;
      loop
         Aux_Message := Get_Message_From_Position;
         if Aux_Message  /= Null_Message then
            --  there is a new movement
            Move.Set_Move (Aux_Message);
         end if;
         Clock_Check_Display := Clock_Check_Display + To_Time_Span (0.1);
         delay until Clock_Check_Display;
      end loop;
   end Check_Display;

   task body Orientation_Task is
      Orientation : Integer;
      Clock_Check_Orientation : Time;
      Period : Duration := 0.3;
   begin
      --  Wait until the Display driver is ready.
      Ada.Synchronous_Task_Control.Suspend_Until_True (Ready3);
      Clock_Check_Orientation := Ada.Real_Time.Clock;
      loop
         Orientation := Get_Orientation;
         if (Orientation > 340 or Orientation < 25) then
            Update_Orientation ('1');
         elsif (Orientation > 26 and Orientation < 70) then
            Update_Orientation ('8');
         elsif (Orientation > 71 and Orientation < 115) then
            Update_Orientation ('7');
         elsif (Orientation > 116 and Orientation < 160) then
            Update_Orientation ('6');
         elsif (Orientation > 161 and Orientation < 205) then
            Update_Orientation ('5');
         elsif (Orientation > 206 and Orientation < 250) then
            Update_Orientation ('4');
         elsif (Orientation > 251 and Orientation < 295) then
            Update_Orientation ('3');
         else
            Update_Orientation ('2');
         end if;
         Clock_Check_Orientation := Clock_Check_Orientation + To_Time_Span (Period);
         delay until Clock_Check_Orientation;
      end loop;
   end Orientation_Task;

end Remote_Control_Car_Tasks;

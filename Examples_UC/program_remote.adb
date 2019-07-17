with STM32.Board;           use STM32.Board;
with HAL.Bitmap;            use HAL.Bitmap;
with HAL.Touch_Panel;       use HAL.Touch_Panel;
with BMP_Fonts;
with LCD_Std_Out;
with Interfaces;
with STM32F7_Disco.Ethernet_Comunication;
with Ada.Real_Time; use Ada.Real_Time;


with Net; use Net;
with Net.Interfaces;
with Net.Headers;
with Net.Buffers;
with Net.Interfaces.STM32;

with Last_Chance_Handler;  pragma Unreferenced (Last_Chance_Handler);

procedure Program_Remote is
   BG : constant Bitmap_Color := (Alpha => 255, others => 64);
   Puntero : TP_Touch_State := Null_Touch_State;
   Thickness : constant Natural := 3;
   Radius : constant Natural := 150;
   Center : constant Point := (625, 300);

   --  The Ethernet interface driver.
   Ifnet     : aliased Net.Interfaces.STM32.STM32_Ifnet;
   Ether  : Net.Headers.Ether_Header_Access;
   Buf    : Net.Buffers.Buffer_Type;
   Direction_Source : constant Ether_Addr := (0, 16#81#, 16#E1#, 5, 5, 0);
   Direction_Mac : constant Ether_Addr := (0, 16#81#, 16#E1#, 5, 5, 1);
   Direction_Destination : constant Ether_Addr := (0, 16#81#, 16#E1#, 5, 5, 2);
   Logger_Protocol : constant Net.Uint16 := 16#1010#;
   Packet  : Net.Buffers.Buffer_Type;
   Message_Information : STM32F7_Disco.Ethernet_Comunication.Message_Type;
   Message_Movement : STM32F7_Disco.Ethernet_Comunication.Message_Type;
   Flag_Send : Boolean := False;

   --  Clocks
   Start_Time : Time;



   type Distance  is (Far, Near, Very_Near);
   --  Next_Move : Move;
   Right_Distance : Character := '1';
   Left_Distance : Character := '2';
   Orientation : Character := '3';

   --  Debug variables
   Aux_Integer : Integer := 0;
   Num_Messages : Integer := 0;

   --  Functions and procedures
   procedure Start;
   procedure Clear;
   procedure Print_Controls;
   procedure Clear_Orientation;
   procedure Update_Orientation;
   procedure Update_Object_Distance;
   function Get_Message_From_Position return STM32F7_Disco.Ethernet_Comunication.Message_Type;



   --------------------------------
   --  Start the tasks
   --------------------------------
   procedure Start is
   begin
      STM32F7_Disco.Ethernet_Comunication.Initialize (Ifnet         => Ifnet,
                                                      Direction_MAC => Direction_Mac);

      --  Initialize touch panel
      Touch_Panel.Initialize;
      --  Initialize LCD
      Display.Initialize;
      Display.Initialize_Layer (1, ARGB_8888);
      LCD_Std_Out.Set_Font (BMP_Fonts.Font16x24);
      LCD_Std_Out.Current_Background_Color := BG;

   end Start;

   procedure Clear is
   begin
      Display.Hidden_Buffer (1).Set_Source (BG);
      Display.Hidden_Buffer (1).Fill;
   end Clear;

   procedure Print_Controls is
   begin
      Display.Hidden_Buffer (1).Set_Source (HAL.Bitmap.White);
      --  Flecha Arriba
      Display.Hidden_Buffer (1).Draw_Line ((200, 25), (250, 75), Thickness);
      Display.Hidden_Buffer (1).Draw_Line ((250, 75), (225, 75), Thickness);
      Display.Hidden_Buffer (1).Draw_Line ((225, 75), (225, 150), Thickness);
      Display.Hidden_Buffer (1).Draw_Line ((225, 150), (175, 150), Thickness);
      Display.Hidden_Buffer (1).Draw_Line ((175, 150), (175, 75), Thickness);
      Display.Hidden_Buffer (1).Draw_Line ((175, 75), (150, 75), Thickness);
      Display.Hidden_Buffer (1).Draw_Line ((150, 75), (200, 25), Thickness);
      --  Flecha Abajo
      Display.Hidden_Buffer (1).Draw_Line ((225, 300), (225, 375), Thickness);
      Display.Hidden_Buffer (1).Draw_Line ((225, 375), (250, 375), Thickness);
      Display.Hidden_Buffer (1).Draw_Line ((250, 375), (200, 425), Thickness);
      Display.Hidden_Buffer (1).Draw_Line ((200, 425), (150, 375), Thickness);
      Display.Hidden_Buffer (1).Draw_Line ((150, 375), (175, 375), Thickness);
      Display.Hidden_Buffer (1).Draw_Line ((175, 375), (175, 300), Thickness);
      Display.Hidden_Buffer (1).Draw_Line ((175, 300), (225, 300), Thickness);
      --  Flecha Izquierda
      Display.Hidden_Buffer (1).Draw_Line ((150, 200), (150, 250), Thickness);
      Display.Hidden_Buffer (1).Draw_Line ((150, 250), (075, 250), Thickness);
      Display.Hidden_Buffer (1).Draw_Line ((075, 250), (075, 275), Thickness);
      Display.Hidden_Buffer (1).Draw_Line ((075, 275), (025, 225), Thickness);
      Display.Hidden_Buffer (1).Draw_Line ((025, 225), (075, 175), Thickness);
      Display.Hidden_Buffer (1).Draw_Line ((075, 175), (075, 200), Thickness);
      Display.Hidden_Buffer (1).Draw_Line ((075, 200), (150, 200), Thickness);

      --  Flecha Derecha
      Display.Hidden_Buffer (1).Draw_Line ((250, 200), (325, 200), Thickness);
      Display.Hidden_Buffer (1).Draw_Line ((325, 200), (325, 175), Thickness);
      Display.Hidden_Buffer (1).Draw_Line ((325, 175), (375, 225), Thickness);
      Display.Hidden_Buffer (1).Draw_Line ((375, 225), (325, 275), Thickness);
      Display.Hidden_Buffer (1).Draw_Line ((325, 275), (325, 250), Thickness);
      Display.Hidden_Buffer (1).Draw_Line ((325, 250), (250, 250), Thickness);
      Display.Hidden_Buffer (1).Draw_Line ((250, 250), (250, 200), Thickness);
      --  Linea Separadora
      Display.Hidden_Buffer (1).Draw_Vertical_Line ((400, 0), 480);
      Display.Hidden_Buffer (1).Draw_Vertical_Line ((401, 0), 480);
      Display.Hidden_Buffer (1).Draw_Vertical_Line ((402, 0), 480);
      --  Circulo Brujula
      Display.Hidden_Buffer (1).Draw_Circle (Center, Radius);
      Display.Hidden_Buffer (1).Draw_Circle (Center, Radius + 1);
      Display.Hidden_Buffer (1).Draw_Circle (Center, Radius + 2);
      Display.Update_Layer (1, Copy_Back => True);

   end Print_Controls;

   procedure Clear_Orientation is
   begin
      Display.Hidden_Buffer (1).Set_Source (BG);
      Display.Hidden_Buffer (1).Fill_Circle (Center => Center, Radius => Radius);
      Display.Update_Layer (1, Copy_Back => True);

   end Clear_Orientation;

   procedure Update_Orientation is
   begin
      Clear_Orientation;
      Display.Hidden_Buffer (1).Set_Source (HAL.Bitmap.Green);

      case Orientation is
         when '1' =>
            --  NO
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
   procedure Update_Object_Distance is

   begin
      Display.Hidden_Buffer (1).Set_Source (HAL.Bitmap.White);

      Display.Hidden_Buffer (1).Cubic_Bezier (P1        => (500, 150),
                                              P2        => (600, 50),
                                              P3        => (650, 50),
                                              P4        => (750, 150),
                                              N         => 4,
                                              Thickness => Thickness);
      --  Left sensor
      case Left_Distance is
         when '1' =>
            Display.Hidden_Buffer (1).Set_Source (HAL.Bitmap.Yellow);
            Display.Hidden_Buffer (1).Draw_Line ((600, 40), (480, 105), Thickness);
         when '2' =>
            Display.Hidden_Buffer (1).Set_Source (HAL.Bitmap.Orange);
            Display.Hidden_Buffer (1).Draw_Line ((615, 45), (490, 115), Thickness);
         when '3' =>
            Display.Hidden_Buffer (1).Set_Source (HAL.Bitmap.Red);
            Display.Hidden_Buffer (1).Draw_Line ((625, 50), (500, 125), Thickness);
         when others =>
            null;
      end case;
      --  Right sensor
      case Right_Distance is
         when '1' =>
            Display.Hidden_Buffer (1).Set_Source (HAL.Bitmap.Yellow);
            Display.Hidden_Buffer (1).Draw_Line ((640, 40), (770, 105), Thickness);
         when '2' =>
            Display.Hidden_Buffer (1).Set_Source (HAL.Bitmap.Orange);
            Display.Hidden_Buffer (1).Draw_Line ((635, 45), (754, 115), Thickness);
         when '3' =>
            Display.Hidden_Buffer (1).Set_Source (HAL.Bitmap.Red);
            Display.Hidden_Buffer (1).Draw_Line ((625, 50), (750, 125), Thickness);
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
            LCD_Std_Out.Put (X => 500, Y => 100, Msg => "Arriba   ");
            Aux_Message := "11111111111111111111111111111111111111111111111111";
            --  arrow down
         elsif Puntero.Y >= 300 and Puntero.Y <= 425 then
            LCD_Std_Out.Put (X => 500, Y => 100, Msg => "Abajo    ");
            Aux_Message := "33333333333333333333333333333333333333333333333333";
         end if;

         --  Check arrow left or right
      elsif Puntero.Y >= 175 and Puntero.Y <= 275  then
         --  arrow left
         if Puntero.X >= 25 and Puntero.X <= 250 then
            LCD_Std_Out.Put (X => 500, Y => 100, Msg => "Izquierda");
            Aux_Message := "44444444444444444444444444444444444444444444444444";
            --  arrow right
         elsif Puntero.X >= 250 and Puntero.X <= 375 then
            LCD_Std_Out.Put (X => 500, Y => 100, Msg => "Derecha  ");
            Aux_Message := "22222222222222222222222222222222222222222222222222";

         end if;
      else
         --  stay still
         Aux_Message := "00000000000000000000000000000000000000000000000000";
      end if;

      return Aux_Message;
   end Get_Message_From_Position;
begin

   Start;
   Clear;
   Print_Controls;

   loop

      Start_Time := Ada.Real_Time.Clock;
      Orientation := '2';
      Update_Orientation;
      Right_Distance := '2';
      Left_Distance := '1';
      Update_Object_Distance;
      Message_Movement := Get_Message_From_Position;

      Flag_Send :=  STM32F7_Disco.Ethernet_Comunication.Send_Message (Buffer        => Buf,
                                                                      Ifnet         => Ifnet,
                                                                      Ether         => Ether,
                                                                      IP_Src        => Direction_Source,
                                                                      IP_Dst        => Direction_Destination,
                                                                      Protocol      => Logger_Protocol,
                                                                      Message       => Message_Movement);
      if Flag_Send then
         LCD_Std_Out.Put (X => 1, Y => 1, Msg => "Message " & Num_Messages'Img & " send");
         Num_Messages := Num_Messages + 1;
      end if;

      Message_Information := STM32F7_Disco.Ethernet_Comunication.Get_Message (Ifnet  => Ifnet, Packet => Packet);

      Orientation := Message_Information (40);
      Left_Distance := Message_Information (14);
      Right_Distance := Message_Information (7);

      delay until Start_Time + To_Time_Span (0.4);
   end loop;

end Program_Remote;

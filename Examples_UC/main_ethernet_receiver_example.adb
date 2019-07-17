--  ethernet
with STM32F7_Disco.Ethernet_Comunication; use STM32F7_Disco.Ethernet_Comunication;

with Net; use Net;
with Net.Buffers;
with Net.Headers;
with Net.Interfaces;  -- Ifnet
with Net.Interfaces.STM32;  --  Ifnet
with Interfaces.C; use Interfaces.C; -- int
with Ada.Real_Time; -- delay

--  Display
with BMP_Fonts;
with STM32.Board;
with LCD_Std_Out;

with Interfaces; use Interfaces;
with HAL; use HAL;
with HAL.Bitmap;
with STM32.RNG.Interrupts;

procedure Main_Ethernet_Receiver_Example is

   --  The Ethernet interface driver.
   Ifnet : aliased Net.Interfaces.STM32.STM32_Ifnet;

   Buf : Net.Buffers.Buffer_Type;
   Source_Address : Ether_Addr := (0, 16#81#, 16#E1#, 5, 5, 0);
   Logger_Protocol : Net.Uint16 := 16#1010#;
   Flag_Send : Boolean := False;
   Num_Messages_Received : int := 0;
   --  50 character message
   Message : Message_Type;
   --  Packet to receive
   Packet : Net.Buffers.Buffer_Type;

begin
   --  Initialize the display
   STM32.Board.Display.Initialize;
   STM32.Board.Display.Initialize_Layer (1, HAL.Bitmap.ARGB_1555);
   LCD_Std_Out.Set_Font (BMP_Fonts.Font16x24);
   LCD_Std_Out.Put (0, 0, "Receptor");
   STM32.Board.Display.Update_Layer (1);

   Initialize (Ifnet         => Ifnet,
               Mac_Src => Source_Address);

   LCD_Std_Out.Put (0, 25, "Stm32 initialize as receptor");

   loop
      Message :=  Get_Message (Ifnet  => Ifnet, Packet => Packet);

      Num_Messages_Received := Num_Messages_Received + 1;

      LCD_Std_Out.Put (0, 150, "Message " & Num_Messages_Received'Img & " received");
      LCD_Std_Out.Put (0, 200, "fist 25 " & Message (1 .. 25));
      LCD_Std_Out.Put (0, 225, "Second 25 " & Message (26 .. 50));

   end loop;

end Main_Ethernet_Receiver_Example;

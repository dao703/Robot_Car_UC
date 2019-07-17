--  ethernet
with STM32F7_Disco.Ethernet_Comunication; use STM32F7_Disco.Ethernet_Comunication;

with Net; use Net;
with Net.Buffers;
with Net.Headers;
with Net.Interfaces;  -- Ifnet
with Net.Interfaces.STM32;  --  Ifnet
with Ada.Real_Time;

--  Display
with BMP_Fonts;
with STM32.Board;
with LCD_Std_Out;

with Interfaces; use Interfaces;
with HAL; use HAL;
with HAL.Bitmap;

procedure Main_Ethernet_Transmitter_Example is

   --  The Ethernet interface driver.
   Ifnet     : aliased Net.Interfaces.STM32.STM32_Ifnet;

   Ether  : Net.Headers.Ether_Header_Access;
   Buf    : Net.Buffers.Buffer_Type;
   Destination_Address : constant Ether_Addr := (0, 16#81#, 16#E1#, 5, 5, 0);
   Source_Address : constant Ether_Addr      := (0, 16#81#, 16#E1#, 5, 5, 1);
   Logger_Protocol : constant Net.Uint16 := 16#1010#;
   Flag_Send : Boolean := False;
   pragma Unreferenced (Flag_Send);
   Num_Messages_Sent : Integer := 0;
   --  50 character message
   Message : Message_Type;  --  "0123456789.abcdeefgijklmnopqrstuvwxyzuuuuuuuuuuuuu";

begin
   --  Initialize the display
   STM32.Board.Display.Initialize;
   STM32.Board.Display.Initialize_Layer (1, HAL.Bitmap.ARGB_1555);
   LCD_Std_Out.Set_Font (BMP_Fonts.Font16x24);

   Initialize (Ifnet         => Ifnet,
               Mac_Src => Source_Address);

   LCD_Std_Out.Put (0, 25, "Board initialized as transmitter");

   loop

      case Num_Messages_Sent mod 5 is
         when 0 => Message := "11111111111111111111111111111111111111111111111111";
         when 1 => Message := "22222222222222222222222222222222222222222222222222";
         when 2 => Message := "33333333333333333333333333333333333333333333333333";
         when 3 => Message := "44444444444444444444444444444444444444444444444444";
         when others => Message := "00000000000000000000000000000000000000000000000000";

      end case;
      Flag_Send :=  Send_Message (Buffer        => Buf,
                                  Ifnet         => Ifnet,
                                  Ether         => Ether,
                                  Mac_Src       => Source_Address,
                                  Mac_Dst       => Destination_Address,
                                  Protocol      => Logger_Protocol,
                                  Message       => Message);


      Num_Messages_Sent := Num_Messages_Sent + 1;
      LCD_Std_Out.Put (0, 80, "Message " & Num_Messages_Sent'Img & " Sent");

      delay until Ada.Real_Time. "+" (Left  => Ada.Real_Time.Clock,
                                      Right =>  Ada.Real_Time.Milliseconds (500));

   end loop;



end Main_Ethernet_Transmitter_Example;

with System;
with HAL;

package body STM32F7_Disco.Ethernet_Comunication is

   ------------------------------------------------------------
   --  Initiali the the network interface.
   ------------------------------------------------------------

   procedure Initialize (Ifnet : in out Net.Interfaces.STM32.STM32_Ifnet;
                         Mac_Src : Ether_Addr) is
      The_Address : System.Address;
      Size        : Net.Uint32 := NET_BUFFER_SIZE;
   begin

      STM32.SDRAM.Initialize;
      --  Setup some receive buffers and initialize the Ethernet driver.
      The_Address := STM32.SDRAM.Reserve (Amount => HAL.UInt32 (Size));
      Net.Buffers.Add_Region (The_Address, Size);
      Ifnet.Mac := Mac_Src;
      Ifnet.Initialize;
   end Initialize;

   ------------------------------------------------------------
   --  Send one message
   --  The Message includes source, destination, protocol and the string
   ------------------------------------------------------------
   function Send_Message (Buffer : in out Net.Buffers.Buffer_Type;
                          Ifnet : in out Net.Interfaces.STM32.STM32_Ifnet;
                          Ether : in out Net.Headers.Ether_Header_Access;
                          Mac_Src : Ether_Addr;
                          Mac_Dst : Ether_Addr; Protocol : Uint16;
                          Message :  Message_Type) return Boolean is
   begin
      Buffer.Allocate;  --  Buf is not null
      Buffer.Set_Type (Kind => Net.Buffers.ETHER_PACKET); -- ethernet buffer type
      Ether := Buffer.Ethernet;
      Ether.Ether_Shost := Mac_Src;  -- source
      Ether.Ether_Dhost := Mac_Dst;  -- destination
      Ether.Ether_Type  := Net.Headers.To_Network (Protocol);
      Buffer.Put_String (Value     => Message,  -- 50 character
                         With_Null => True);
      Buffer.Set_Length (64);
      Ifnet.Send (Buf => Buffer);
      return True;
   end Send_Message;

   ------------------------------------------------------------
   --  Get the text in the ethernet package
   ------------------------------------------------------------
   function Get_Message (Ifnet : in out Net.Interfaces.STM32.STM32_Ifnet;
                         Packet : in out Net.Buffers.Buffer_Type) return Message_Type is
      Actual_Message : Message_Type;
   begin
      Packet.Set_Type (Net.Buffers.ETHER_PACKET);
      Net.Buffers.Allocate (Packet);
      --  Wait until The Message Arrive
      Ifnet.Receive (Packet);
      Packet.Get_String (Into =>  Actual_Message);
      Packet.Release;
      return  Actual_Message;
   end Get_Message;

end STM32F7_Disco.Ethernet_Comunication;

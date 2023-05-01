library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.std_logic_textio.all;
use std.textio.all;

package handshake_pkg is

   -- BFM Handle Type
   type t_pkg_handle is record
      req      : std_logic;   -- driven by the test controller through the BFM's package
      ack      : std_logic;   -- driven by the BFM
      ready    : std_logic;   -- driven by the BFM
   end record;

    -- send a request to the BFM (usable outside of the BFM)
   procedure bfm_send_request (
     signal   handle      : inout t_pkg_handle;
     constant log_name    : string  := "handshake__bfm";
     constant timeout     : time    := 10 us;
     constant blocking    : boolean := false  -- waits until the processing is finished (BFM is ready again)
   );

   -- wait until a BFM reqeust is issued (usable in a BFM)
   procedure bfm_wait_for_request(
      signal   handle      : inout t_pkg_handle;
      constant log_name    : in    string  := "bfm_wait_for_request"
   );

   -- indicate that the BFM request was accepted (usable in a BFM)
   procedure bfm_ack_request(
      signal   handle      : inout t_pkg_handle;
      constant log_name    : in    string  := "bfm_ack_request"
   );

   -- Initialization routine for the BFM handles
   function t_pkg_handle_init return t_pkg_handle;

   function to_hstring (SLV : std_logic_vector) return string;

end package;


package body handshake_pkg is

   -- send a request to the BFM (usable outside of the BFM)
   procedure bfm_send_request (
     signal   handle      : inout t_pkg_handle;
     constant log_name    : string  := "handshake__bfm";
     constant timeout     : time    := 10 us;
     constant blocking    : boolean := false  -- waits until the processing is finished (BFM is ready again)
   ) is
   begin
   --   report "handshake__bfm.bfm_send_request";

     -- make sure that the BFM is even present (somebody drives the ready signal)
     if handle.ready /= '1' and handle.ready /= '0' then
        report ("Skipping this BFM, it is not initialized or present, because the 'ready' signal is " & std_logic'image(handle.ready) );
        return;
     end if;
   
     -- wait until BFM is ready to process command
     while handle.ready /= '1' loop
        wait until handle.ready = '1' for timeout;
        if handle.ready /= '1' then
           report "The BFM is not ready, timeout " severity error;
           -- keep waiting without timeout now
           wait until handle.ready = '1';
        end if;
     end loop;

   --   report "handshake__bfm.bfm_send_request" ;
     -- wake up the BFM
     handle.req                <= '1';
     -- wait until the command is acknowledged and release the request
     wait on handle.ack;
     handle.req                <= 'Z';

   --   report "handshake__bfm.bfm_send_request";
     -- wait until finished when blocking
     if blocking and handle.ready /= '1' then
        wait until handle.ready = '1';
     end if;
     -- insert delta-cycle to let the BFM run
     wait for 0 ns;
   --   report "handshake__bfm.bfm_send_request";
   end procedure;


   -- wait until a BFM reqeust is issued (usable in a BFM)
   procedure bfm_wait_for_request(
      signal   handle      : inout t_pkg_handle;
      constant log_name    : in    string  := "bfm_wait_for_request"
   ) is 
   begin
      report "waiting ...";
      -- Wait for Request
      handle.ready <= '1';
      --report ("handle.ready = " & std_logic'image(handle.ready));
      wait until handle.req = '1';
      handle.ready <= '0';
      report ".... ready.";
   end procedure;


   -- indicate that the BFM request was accepted (usable in a BFM)
   procedure bfm_ack_request(
      signal   handle      : inout t_pkg_handle;
      constant log_name    : in    string  := "bfm_ack_request"
   ) is 
   begin
      -- transition from '1' to '0'
      -- transition from 'Z'/'0' to '1'
      if handle.ack = '1' then
         handle.ack <= '0';
      else
         handle.ack <= '1';
      end if;
      report "done";
   end procedure;

   -- Initialization routine for the BFM handles
   function t_pkg_handle_init return t_pkg_handle is   
      variable ret : t_pkg_handle;
   begin
      ret := (
         req   => 'W',
         ack   => 'Z',
         ready => 'Z'
      );
      --end loop;
      return ret;
   end function;

   -- translate vector to string
   function to_hstring (SLV : std_logic_vector) return string is
      variable L : LINE;
    begin
      hwrite(L,SLV);
      return L.all;
   end function to_hstring;

end package body;
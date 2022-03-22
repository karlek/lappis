#![no_std]
#![no_main]

#[link(name = "kernel")]
extern "C" {
    fn debug_buffer(buf: *mut u8, len: u64);
}

#[no_mangle]
pub extern "C" fn bar() -> u8 {
    // Initialize a buffer of all zeroes
    let mut buf: [u8; 13] = [72, 101, 108, 108, 111, 44, 32, 82, 117, 115, 116, 33, 10];
    unsafe {
        debug_buffer(buf.as_mut_ptr() as *mut u8, buf.len() as u64);
    }
    return 47;
}

use core::panic::PanicInfo;

/// This function is called on panic.
#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}

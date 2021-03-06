#ifndef PIC_H
#define PIC_H

#include <stdint.h>

#include "ports.h"
#include "serial.h"

#define PIC1         0x20 /* IO base address for primary PIC */
#define PIC2         0xA0 /* IO base address for secondary PIC */
#define PIC1_COMMAND PIC1
#define PIC1_DATA    (PIC1 + 1)
#define PIC2_COMMAND PIC2
#define PIC2_DATA    (PIC2 + 1)
#define PIC_EOI      0x20 /* End-of-interrupt command code */

/* reinitialize the PIC controllers, giving them specified vector offsets
   rather than 8h and 70h, as configured by default */

#define ICW1_ICW4      0x01 /* ICW4 (not) needed */
#define ICW1_SINGLE    0x02 /* Single (cascade) mode */
#define ICW1_INTERVAL4 0x04 /* Call address interval 4 (8) */
#define ICW1_LEVEL     0x08 /* Level triggered (edge) mode */
#define ICW1_INIT      0x10 /* Initialization - required! */

#define ICW4_8086          0x01 /* 8086/88 (MCS-80/85) mode */
#define ICW4_AUTO          0x02 /* Auto (normal) EOI */
#define ICW4_BUF_SECONDARY 0x08 /* Buffered mode/secondary */
#define ICW4_BUF_PRIMARY   0x0C /* Buffered mode/primary */
#define ICW4_SFNM          0x10 /* Special fully nested (not) */

/*
arguments:
    offset1 - vector offset for primary PIC
        vectors on the primary become offset1..offset1+7
    offset2 - same for secondary PIC: offset2..offset2+7
*/
void PIC_remap(uint16_t offset1, uint16_t offset2);
void PIC_sendEOI(uint8_t irq);

#endif

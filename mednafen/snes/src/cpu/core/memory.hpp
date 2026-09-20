alwaysinline uint8_t op_readpc() {
  return op_read((regs.pc.b << 16) + regs.pc.w++);
}

alwaysinline uint8_t op_readstack() {
  uint16_t addr = regs.s.w;
  regs.e ? regs.s.l++ : regs.s.w++;
  return op_read(addr);
}

alwaysinline uint8_t op_readstackn() {
  return op_read(++regs.s.w);
}

alwaysinline uint8_t op_readaddr(uint32_t addr) {
  return op_read((uint16_t)addr);
}

alwaysinline uint8_t op_readlong(uint32_t addr) {
  return op_read(addr & 0xffffff);
}

alwaysinline uint8_t op_readdbr(uint32_t addr) {
  return op_read(((regs.db << 16) + addr) & 0xffffff);
}

alwaysinline uint8_t op_readpbr(uint32_t addr) {
  return op_read((regs.pc.b << 16) | (addr & 0xffff));
}

alwaysinline uint8_t op_readdp(uint32_t addr) {
  uint32_t base = regs.d;
  if(regs.e) {
    // Optimized emulation mode direct page wrap (zero-page wrapping within bank 0)
    return op_read((base & 0xff00) | ((base + (uint16_t)addr) & 0xff));
  }
  return op_read((base + (uint16_t)addr) & 0xffff);
}

alwaysinline uint8_t op_readsp(uint32_t addr) {
  return op_read((regs.s + (uint16_t)addr) & 0xffff);
}

alwaysinline void op_writestack(uint8_t data) {
  op_write(regs.s.w, data);
  regs.e ? regs.s.l-- : regs.s.w--;
}

alwaysinline void op_writestackn(uint8_t data) {
  op_write(regs.s.w--, data);
}

alwaysinline void op_writeaddr(uint32_t addr, uint8_t data) {
  op_write((uint16_t)addr, data);
}

alwaysinline void op_writelong(uint32_t addr, uint8_t data) {
  op_write(addr & 0xffffff, data);
}

alwaysinline void op_writedbr(uint32_t addr, uint8_t data) {
  op_write(((regs.db << 16) + addr) & 0xffffff, data);
}

alwaysinline void op_writepbr(uint32_t addr, uint8_t data) {
  op_write((regs.pc.b << 16) | (addr & 0xffff), data);
}

alwaysinline void op_writedp(uint32_t addr, uint8_t data) {
  uint32_t base = regs.d;
  if(regs.e) {
    op_write((base & 0xff00) | ((base + (uint16_t)addr) & 0xff), data);
  } else {
    op_write((base + (uint16_t)addr) & 0xffff, data);
  }
}

alwaysinline void op_writesp(uint32_t addr, uint8_t data) {
  op_write((regs.s + (uint16_t)addr) & 0xffff, data);
}
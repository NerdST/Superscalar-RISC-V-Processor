import sys
import re
import os

REG_ALIASES = {
    'zero': 0, 'ra': 1, 'sp': 2, 'gp': 3, 'tp': 4,
    't0': 5, 't1': 6, 't2': 7,
    's0': 8, 'fp': 8, 's1': 9,
    'a0': 10, 'a1': 11, 'a2': 12, 'a3': 13, 'a4': 14, 'a5': 15, 'a6': 16, 'a7': 17,
    's2': 18, 's3': 19, 's4': 20, 's5': 21, 's6': 22, 's7': 23, 's8': 24, 's9': 25, 's10': 26, 's11': 27,
    't3': 28, 't4': 29, 't5': 30, 't6': 31,
}


def parse_reg(token):
    t = token.strip().lower()
    if t.startswith('x') and t[1:].isdigit():
        idx = int(t[1:])
        if 0 <= idx <= 31:
            return idx
    if t in REG_ALIASES:
        return REG_ALIASES[t]
    raise ValueError(f"Invalid register: {token}")


def parse_imm(token):
    return int(token.strip(), 0)


def mask(value, bits):
    return value & ((1 << bits) - 1)


def encode_r(funct7, rs2, rs1, funct3, rd, opcode):
    return ((funct7 & 0x7F) << 25) | ((rs2 & 0x1F) << 20) | ((rs1 & 0x1F) << 15) | ((funct3 & 0x7) << 12) | ((rd & 0x1F) << 7) | (opcode & 0x7F)


def encode_i(imm, rs1, funct3, rd, opcode):
    return ((mask(imm, 12) & 0xFFF) << 20) | ((rs1 & 0x1F) << 15) | ((funct3 & 0x7) << 12) | ((rd & 0x1F) << 7) | (opcode & 0x7F)


def encode_s(imm, rs2, rs1, funct3, opcode):
    i = mask(imm, 12)
    imm_11_5 = (i >> 5) & 0x7F
    imm_4_0 = i & 0x1F
    return (imm_11_5 << 25) | ((rs2 & 0x1F) << 20) | ((rs1 & 0x1F) << 15) | ((funct3 & 0x7) << 12) | (imm_4_0 << 7) | (opcode & 0x7F)


def encode_b(imm, rs2, rs1, funct3, opcode):
    i = mask(imm, 13)
    bit12 = (i >> 12) & 0x1
    bit11 = (i >> 11) & 0x1
    bits10_5 = (i >> 5) & 0x3F
    bits4_1 = (i >> 1) & 0xF
    return (bit12 << 31) | (bits10_5 << 25) | ((rs2 & 0x1F) << 20) | ((rs1 & 0x1F) << 15) | ((funct3 & 0x7) << 12) | (bits4_1 << 8) | (bit11 << 7) | (opcode & 0x7F)


def encode_u(imm, rd, opcode):
    # U-type immediate in assembly syntax is a 20-bit value; hardware places it in [31:12].
    return ((mask(imm, 20) << 12) & 0xFFFFF000) | ((rd & 0x1F) << 7) | (opcode & 0x7F)


def encode_j(imm, rd, opcode):
    i = mask(imm, 21)
    bit20 = (i >> 20) & 0x1
    bits10_1 = (i >> 1) & 0x3FF
    bit11 = (i >> 11) & 0x1
    bits19_12 = (i >> 12) & 0xFF
    return (bit20 << 31) | (bits19_12 << 12) | (bit11 << 20) | (bits10_1 << 21) | ((rd & 0x1F) << 7) | (opcode & 0x7F)


def strip_comment(line):
    work = line.rstrip('\n')
    hash_idx = work.find('#')
    if hash_idx != -1:
        work = work[:hash_idx]
    return work.strip()


def normalize_tokens(instr):
    return instr.replace(',', ' ').replace('(', ' ').replace(')', ' ').split()


def parse_source(input_file):
    instructions = []
    labels = {}
    pc = 0

    with open(input_file, 'r') as f:
        for line_no, raw in enumerate(f, start=1):
            stripped = raw.strip()
            if not stripped:
                continue
            if stripped.startswith('#') or stripped.startswith(';'):
                continue

            body = strip_comment(raw)
            if not body:
                continue

            while ':' in body:
                left, right = body.split(':', 1)
                label = left.strip()
                if not label:
                    raise ValueError(f"Invalid label on line {line_no}: {raw.strip()}")
                labels[label] = pc
                body = right.strip()
                if not body:
                    break

            if body:
                instructions.append((pc, line_no, body))
                pc += 4

    return instructions, labels


def resolve_imm_or_label(token, labels, pc):
    t = token.strip()
    if t in labels:
        return labels[t] - pc
    return parse_imm(t)


def assemble_instruction(instr_text, labels, pc, line_no):
    tokens = normalize_tokens(instr_text)
    if not tokens:
        raise ValueError(f"Empty instruction on line {line_no}")

    op = tokens[0].lower()

    if op == 'nop':
        return 0x00000013

    if op in ('add', 'sub', 'and', 'or', 'xor', 'sll', 'srl', 'sra', 'slt', 'sltu',
              'mul', 'mulh', 'mulhsu', 'mulhu', 'div', 'divu', 'rem', 'remu'):
        if len(tokens) != 4:
            raise ValueError(f"Invalid R-type format on line {line_no}: {instr_text}")
        rd = parse_reg(tokens[1])
        rs1 = parse_reg(tokens[2])
        rs2 = parse_reg(tokens[3])
        r_map = {
            'add':    (0x00, 0x0), 'sub':   (0x20, 0x0), 'and': (0x00, 0x7), 'or': (0x00, 0x6),
            'xor':    (0x00, 0x4), 'sll':   (0x00, 0x1), 'srl': (0x00, 0x5), 'sra': (0x20, 0x5),
            'slt':    (0x00, 0x2), 'sltu':  (0x00, 0x3),
            # M-extension
            'mul':    (0x01, 0x0), 'mulh':  (0x01, 0x1), 'mulhsu': (0x01, 0x2), 'mulhu': (0x01, 0x3),
            'div':    (0x01, 0x4), 'divu':  (0x01, 0x5), 'rem':    (0x01, 0x6), 'remu':  (0x01, 0x7),
        }
        funct7, funct3 = r_map[op]
        return encode_r(funct7, rs2, rs1, funct3, rd, 0x33)

    if op in ('addi', 'andi', 'ori', 'xori', 'slti', 'sltiu'):
        if len(tokens) != 4:
            raise ValueError(f"Invalid I-type format on line {line_no}: {instr_text}")
        rd = parse_reg(tokens[1])
        rs1 = parse_reg(tokens[2])
        imm = parse_imm(tokens[3])
        i_map = {'addi': 0x0, 'andi': 0x7, 'ori': 0x6, 'xori': 0x4, 'slti': 0x2, 'sltiu': 0x3}
        return encode_i(imm, rs1, i_map[op], rd, 0x13)

    if op in ('slli', 'srli', 'srai'):
        if len(tokens) != 4:
            raise ValueError(f"Invalid shift-I format on line {line_no}: {instr_text}")
        rd = parse_reg(tokens[1])
        rs1 = parse_reg(tokens[2])
        shamt = parse_imm(tokens[3])
        if not (0 <= shamt <= 31):
            raise ValueError(f"Shift amount out of range on line {line_no}: {shamt}")
        if op == 'slli':
            imm = shamt
            funct3 = 0x1
        elif op == 'srli':
            imm = shamt
            funct3 = 0x5
        else:
            imm = (0x20 << 5) | shamt
            funct3 = 0x5
        return encode_i(imm, rs1, funct3, rd, 0x13)

    if op == 'lw':
        if len(tokens) != 4:
            raise ValueError(f"Invalid lw format on line {line_no}: {instr_text}")
        rd = parse_reg(tokens[1])
        imm = parse_imm(tokens[2])
        rs1 = parse_reg(tokens[3])
        return encode_i(imm, rs1, 0x2, rd, 0x03)

    if op == 'jalr':
        if len(tokens) != 4:
            raise ValueError(f"Invalid jalr format on line {line_no}: {instr_text}")
        rd = parse_reg(tokens[1])
        imm = parse_imm(tokens[2])
        rs1 = parse_reg(tokens[3])
        return encode_i(imm, rs1, 0x0, rd, 0x67)

    if op == 'sw':
        if len(tokens) != 4:
            raise ValueError(f"Invalid sw format on line {line_no}: {instr_text}")
        rs2 = parse_reg(tokens[1])
        imm = parse_imm(tokens[2])
        rs1 = parse_reg(tokens[3])
        return encode_s(imm, rs2, rs1, 0x2, 0x23)

    if op in ('beq', 'bne', 'blt', 'bge', 'bltu', 'bgeu'):
        if len(tokens) != 4:
            raise ValueError(f"Invalid branch format on line {line_no}: {instr_text}")
        rs1 = parse_reg(tokens[1])
        rs2 = parse_reg(tokens[2])
        imm = resolve_imm_or_label(tokens[3], labels, pc)
        b_map = {'beq': 0x0, 'bne': 0x1, 'blt': 0x4, 'bge': 0x5, 'bltu': 0x6, 'bgeu': 0x7}
        return encode_b(imm, rs2, rs1, b_map[op], 0x63)

    if op in ('lui', 'auipc'):
        if len(tokens) != 3:
            raise ValueError(f"Invalid U-type format on line {line_no}: {instr_text}")
        rd = parse_reg(tokens[1])
        imm = parse_imm(tokens[2])
        opcode = 0x37 if op == 'lui' else 0x17
        return encode_u(imm, rd, opcode)

    if op == 'jal':
        if len(tokens) != 3:
            raise ValueError(f"Invalid jal format on line {line_no}: {instr_text}")
        rd = parse_reg(tokens[1])
        imm = resolve_imm_or_label(tokens[2], labels, pc)
        return encode_j(imm, rd, 0x6F)

    raise ValueError(f"Unsupported instruction on line {line_no}: {op}")


def assemble_to_machine_code(input_file):
    instructions, labels = parse_source(input_file)
    machine_codes = []
    for pc, line_no, instr in instructions:
        code = assemble_instruction(instr, labels, pc, line_no)
        machine_codes.append(f"{code:08x}")
    return machine_codes

def assemble_file_to_txt(input_file, output_file=None):
    """
    Extracts machine code from RISC-V assembly file and saves to a unified memory image file.
    
    Args:
        input_file (str): The path to the input assembly file.
        output_file (str): The path to the output memory image file. If None, uses same name with .mem extension.
    """
    if output_file is None:
        # Default output: same filename with .mem extension
        output_file = os.path.splitext(input_file)[0] + '.mem'
    
    machine_codes = assemble_to_machine_code(input_file)
    
    if not machine_codes:
        print(f"Warning: No machine code found in '{input_file}'")
        return
    
    # Write machine codes to output file
    os.makedirs(os.path.dirname(output_file) or '.', exist_ok=True)
    with open(output_file, 'w') as f:
        for code in machine_codes:
            f.write(code + '\n')
    
    print(f"Assembly file '{input_file}' processed.")
    print(f"Machine code extracted: {len(machine_codes)} instructions")
    print(f"Machine code memory image saved to '{output_file}'")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python assemble.py <input_assembly_file.s>")
        sys.exit(1)
    
    input_filename = sys.argv[1]
    assemble_file_to_txt(input_filename)


#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

//fmt 0 is LI, 1 is R4, 2 is R3, op is the R4 [22:20] or R3 [18:15] code
static const struct {
    const char *name;
    int fmt;
    unsigned op;
} ops[] = {
    {"LI", 0, 0}, {"SIMALS", 1, 0}, {"SIMAHS", 1, 1}, {"SIMSLS", 1, 2}, {"SIMSHS", 1, 3},
    {"SLMALS", 1, 4}, {"SLMAHS", 1, 5}, {"SLMSLS", 1, 6}, {"SLMSHS", 1, 7},
    {"NOP", 2, 0}, {"ABSDB", 2, 1}, {"AU", 2, 2}, {"CNT1W", 2, 3}, {"AHS", 2, 4}, {"AND", 2, 5},
    {"BCW", 2, 6}, {"MAXWS", 2, 7}, {"MINWS", 2, 8}, {"MLHU", 2, 9}, {"MLHCU", 2, 10},
    {"OR", 2, 11}, {"CNTLZ", 2, 12}, {"ROTW", 2, 13}, {"SFWU", 2, 14}, {"SFHS", 2, 15}
};

//field widths for the underscores in the output, 0 ends the list
static const int widths[3][7] = {{1, 3, 16, 5, 0}, {2, 3, 5, 5, 5, 5, 0}, {2, 8, 5, 5, 5, 0}};

//a $register or a decimal or 0x hex number
static unsigned num(const char *t) {
    if (t[0] == '$') {
        t++;
    }
    return (unsigned)strtoul(t, NULL, (t[0] == '0' && tolower((unsigned char)t[1]) == 'x') ? 16 : 10);
}

int main(int argc, char **argv) {
    static char text[64][256];
    unsigned code[64];
    int fmt[64];
    char buf[256];
    int n = 0;
    FILE *in = fopen(argv[1], "r");
    FILE *out = fopen(argv[2], "w");

    while (fgets(buf, sizeof(buf), in) != NULL) {
        char *s = buf, *tok, *p;
        unsigned v[4] = {0, 0, 0, 0}; // rd, then rs1 or idx, then rs2 or imm or c, then rs3
        int i = 0, k = 0;
        buf[strcspn(buf, "#\r\n")] = '\0'; // drop comment and line end
        for (p = buf + strlen(buf); p > buf && isspace((unsigned char)p[-1]); p--) {
            p[-1] = '\0';
        }
        while (isspace((unsigned char)*s)) {
            s++;
        }
        if (*s == '\0') {
            continue;
        }
        strcpy(text[n], s);
        tok = strtok(s, " \t");
        for (p = tok; *p != '\0'; p++) {
            *p = (char)toupper((unsigned char)*p);
        }
        while (strcmp(ops[i].name, tok) != 0) {
            i++;
        }
        while ((tok = strtok(NULL, ", \t")) != NULL) {
            v[k++] = num(tok);
        }
        fmt[n] = ops[i].fmt;
        if (fmt[n] == 0) {
            code[n] = (v[1] << 21) | (v[2] << 5) | v[0];
        } else if (fmt[n] == 1) {
            code[n] = (2u << 23) | (ops[i].op << 20) | (v[3] << 15) | (v[2] << 10) | (v[1] << 5) | v[0];
        } else {
            code[n] = (3u << 23) | (ops[i].op << 15) | (v[2] << 10) | (v[1] << 5) | v[0];
        }
        n++;
    }

    //pad with NOPs, print each line with underscores between fields
    for (int s = 0; s < 64; s++) {
        int bit = 24;
        if (s >= n) {
            code[s] = 3u << 23;
            fmt[s] = 2;
            strcpy(text[s], "NOP (padding)");
        }
        for (const int *w = widths[fmt[s]]; *w != 0; w++) {
            for (int j = 0; j < *w; j++, bit--) {
                fputc('0' + ((code[s] >> bit) & 1u), out);
            }
            if (w[1] != 0) {
                fputc('_', out);
            }
        }
        fprintf(out, " // %02d: %s\n", s, text[s]);
    }
    fclose(in);
    fclose(out);
    return 0;
}
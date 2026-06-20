/////////////////////////////////////////////////////////////
// Created by: Synopsys DC Ultra(TM) in wire load mode
// Version   : K-2015.06
// Date      : Thu Dec 11 20:28:17 2025
/////////////////////////////////////////////////////////////


module ARITH_0 ( a, b, sel, out1 );
  input [4:0] a;
  input [4:0] b;
  output [4:0] out1;
  input sel;
  wire   n1, n2, n3, n4, n5, n6, n7, n8, n9, n10, n11, n12, n13, n14, n15, n16,
         n17, n18, n19, n20, n21, n22, n23, n24, n25, n26, n27, n28, n29, n30,
         n31, n32, n33, n34, n35, n36, n37, n38, n39, n40, n41, n42, n43, n44,
         n45;

  OR2X1 U1 ( .A(n14), .B(b[3]), .Y(n40) );
  BUFX2 U2 ( .A(n43), .Y(n1) );
  BUFX2 U3 ( .A(n26), .Y(n2) );
  BUFX2 U4 ( .A(n19), .Y(n3) );
  BUFX2 U5 ( .A(n35), .Y(n4) );
  INVX1 U6 ( .A(n18), .Y(n5) );
  AND2X1 U7 ( .A(n20), .B(n13), .Y(n18) );
  INVX1 U8 ( .A(n34), .Y(n6) );
  AND2X1 U9 ( .A(n36), .B(n12), .Y(n34) );
  INVX1 U10 ( .A(n28), .Y(n7) );
  AND2X1 U11 ( .A(b[2]), .B(n30), .Y(n28) );
  BUFX2 U12 ( .A(n38), .Y(n8) );
  BUFX2 U13 ( .A(n45), .Y(n9) );
  BUFX2 U14 ( .A(n31), .Y(n10) );
  AND2X1 U15 ( .A(b[0]), .B(n15), .Y(n16) );
  INVX1 U16 ( .A(n16), .Y(n11) );
  AND2X1 U17 ( .A(a[3]), .B(n33), .Y(n37) );
  INVX1 U18 ( .A(n37), .Y(n12) );
  AND2X1 U19 ( .A(a[1]), .B(n17), .Y(n21) );
  INVX1 U20 ( .A(n21), .Y(n13) );
  BUFX2 U21 ( .A(n41), .Y(n14) );
  INVX1 U22 ( .A(a[0]), .Y(n15) );
  OAI21X1 U23 ( .A(b[0]), .B(n15), .C(n11), .Y(out1[0]) );
  AND2X1 U24 ( .A(b[0]), .B(a[0]), .Y(n24) );
  INVX1 U25 ( .A(sel), .Y(n42) );
  AOI22X1 U26 ( .A(sel), .B(n16), .C(n24), .D(n42), .Y(n19) );
  INVX1 U27 ( .A(b[1]), .Y(n17) );
  OR2X1 U28 ( .A(a[1]), .B(n17), .Y(n20) );
  XNOR2X1 U29 ( .A(n3), .B(n5), .Y(out1[1]) );
  INVX1 U30 ( .A(n20), .Y(n22) );
  OAI21X1 U31 ( .A(n16), .B(n22), .C(n13), .Y(n27) );
  OR2X1 U32 ( .A(n24), .B(b[1]), .Y(n23) );
  AOI22X1 U33 ( .A(n24), .B(b[1]), .C(a[1]), .D(n23), .Y(n31) );
  AOI22X1 U34 ( .A(sel), .B(n27), .C(n10), .D(n42), .Y(n26) );
  INVX1 U35 ( .A(a[2]), .Y(n30) );
  OAI21X1 U36 ( .A(b[2]), .B(n30), .C(n7), .Y(n25) );
  HAX1 U37 ( .A(n2), .B(n25), .YS(out1[2]) );
  INVX1 U38 ( .A(b[2]), .Y(n32) );
  AOI22X1 U39 ( .A(a[2]), .B(n32), .C(n7), .D(n27), .Y(n38) );
  OR2X1 U40 ( .A(n32), .B(n10), .Y(n29) );
  AOI22X1 U41 ( .A(n32), .B(n10), .C(n30), .D(n29), .Y(n41) );
  AOI22X1 U42 ( .A(sel), .B(n8), .C(n14), .D(n42), .Y(n35) );
  INVX1 U43 ( .A(b[3]), .Y(n33) );
  OR2X1 U44 ( .A(a[3]), .B(n33), .Y(n36) );
  XNOR2X1 U45 ( .A(n4), .B(n6), .Y(out1[3]) );
  INVX1 U46 ( .A(n36), .Y(n39) );
  OAI21X1 U47 ( .A(n39), .B(n8), .C(n12), .Y(n44) );
  AOI22X1 U48 ( .A(n14), .B(b[3]), .C(a[3]), .D(n40), .Y(n43) );
  AOI22X1 U49 ( .A(sel), .B(n44), .C(n1), .D(n42), .Y(n45) );
  FAX1 U50 ( .A(n9), .B(b[4]), .C(a[4]), .YS(out1[4]) );
endmodule


module ARITH_1 ( a, b, sel, out1 );
  input [4:0] a;
  input [4:0] b;
  output [4:0] out1;
  input sel;
  wire   n1, n2, n3, n4, n5, n6, n7, n8, n9, n10, n11, n12, n13, n14, n15, n16,
         n17, n18, n19, n20, n21, n22, n23, n24, n25, n26, n27, n28, n29, n30,
         n31, n32, n33, n34, n35, n36, n37, n38, n39, n40, n41, n42, n43, n44,
         n45;

  OR2X1 U1 ( .A(n14), .B(b[3]), .Y(n40) );
  BUFX2 U2 ( .A(n43), .Y(n1) );
  BUFX2 U3 ( .A(n26), .Y(n2) );
  BUFX2 U4 ( .A(n19), .Y(n3) );
  BUFX2 U5 ( .A(n35), .Y(n4) );
  INVX1 U6 ( .A(n18), .Y(n5) );
  AND2X1 U7 ( .A(n20), .B(n13), .Y(n18) );
  INVX1 U8 ( .A(n34), .Y(n6) );
  AND2X1 U9 ( .A(n36), .B(n12), .Y(n34) );
  INVX1 U10 ( .A(n28), .Y(n7) );
  AND2X1 U11 ( .A(b[2]), .B(n30), .Y(n28) );
  BUFX2 U12 ( .A(n38), .Y(n8) );
  BUFX2 U13 ( .A(n45), .Y(n9) );
  BUFX2 U14 ( .A(n31), .Y(n10) );
  AND2X1 U15 ( .A(b[0]), .B(n15), .Y(n16) );
  INVX1 U16 ( .A(n16), .Y(n11) );
  AND2X1 U17 ( .A(a[3]), .B(n33), .Y(n37) );
  INVX1 U18 ( .A(n37), .Y(n12) );
  AND2X1 U19 ( .A(a[1]), .B(n17), .Y(n21) );
  INVX1 U20 ( .A(n21), .Y(n13) );
  BUFX2 U21 ( .A(n41), .Y(n14) );
  INVX1 U22 ( .A(a[0]), .Y(n15) );
  OAI21X1 U23 ( .A(b[0]), .B(n15), .C(n11), .Y(out1[0]) );
  AND2X1 U24 ( .A(b[0]), .B(a[0]), .Y(n24) );
  INVX1 U25 ( .A(sel), .Y(n42) );
  AOI22X1 U26 ( .A(sel), .B(n16), .C(n24), .D(n42), .Y(n19) );
  INVX1 U27 ( .A(b[1]), .Y(n17) );
  OR2X1 U28 ( .A(a[1]), .B(n17), .Y(n20) );
  XNOR2X1 U29 ( .A(n3), .B(n5), .Y(out1[1]) );
  INVX1 U30 ( .A(n20), .Y(n22) );
  OAI21X1 U31 ( .A(n16), .B(n22), .C(n13), .Y(n27) );
  OR2X1 U32 ( .A(n24), .B(b[1]), .Y(n23) );
  AOI22X1 U33 ( .A(n24), .B(b[1]), .C(a[1]), .D(n23), .Y(n31) );
  AOI22X1 U34 ( .A(sel), .B(n27), .C(n10), .D(n42), .Y(n26) );
  INVX1 U35 ( .A(a[2]), .Y(n30) );
  OAI21X1 U36 ( .A(b[2]), .B(n30), .C(n7), .Y(n25) );
  HAX1 U37 ( .A(n2), .B(n25), .YS(out1[2]) );
  INVX1 U38 ( .A(b[2]), .Y(n32) );
  AOI22X1 U39 ( .A(a[2]), .B(n32), .C(n7), .D(n27), .Y(n38) );
  OR2X1 U40 ( .A(n32), .B(n10), .Y(n29) );
  AOI22X1 U41 ( .A(n32), .B(n10), .C(n30), .D(n29), .Y(n41) );
  AOI22X1 U42 ( .A(sel), .B(n8), .C(n14), .D(n42), .Y(n35) );
  INVX1 U43 ( .A(b[3]), .Y(n33) );
  OR2X1 U44 ( .A(a[3]), .B(n33), .Y(n36) );
  XNOR2X1 U45 ( .A(n4), .B(n6), .Y(out1[3]) );
  INVX1 U46 ( .A(n36), .Y(n39) );
  OAI21X1 U47 ( .A(n39), .B(n8), .C(n12), .Y(n44) );
  AOI22X1 U48 ( .A(n14), .B(b[3]), .C(a[3]), .D(n40), .Y(n43) );
  AOI22X1 U49 ( .A(sel), .B(n44), .C(n1), .D(n42), .Y(n45) );
  FAX1 U50 ( .A(n9), .B(b[4]), .C(a[4]), .YS(out1[4]) );
endmodule


module COMBO ( Cin1, Cin2, sel, Cout );
  input [4:0] Cin1;
  input [4:0] Cin2;
  output [4:0] Cout;
  input sel;
  wire   n1, n2, n3, n4, n5, n6;
  wire   [4:0] arth_o;

  ARITH_1 U2_ARITH ( .a(Cin1), .b(Cin2), .sel(sel), .out1(arth_o) );
  AND2X1 U1 ( .A(Cin1[0]), .B(arth_o[0]), .Y(n3) );
  INVX1 U2 ( .A(n3), .Y(n1) );
  OAI21X1 U3 ( .A(Cin1[0]), .B(arth_o[0]), .C(n1), .Y(n2) );
  INVX1 U4 ( .A(n2), .Y(Cout[0]) );
  FAX1 U5 ( .A(arth_o[1]), .B(Cin1[1]), .C(n3), .YC(n4), .YS(Cout[1]) );
  FAX1 U6 ( .A(arth_o[2]), .B(Cin1[2]), .C(n4), .YC(n5), .YS(Cout[2]) );
  FAX1 U7 ( .A(arth_o[3]), .B(Cin1[3]), .C(n5), .YC(n6), .YS(Cout[3]) );
  FAX1 U8 ( .A(Cin1[4]), .B(n6), .C(arth_o[4]), .YS(Cout[4]) );
endmodule


module MY_DESIGN_1 ( Cin1, Cin2, Cout, data1, data2, sel, clk, out1, out2, 
        out3 );
  input [4:0] Cin1;
  input [4:0] Cin2;
  output [4:0] Cout;
  input [4:0] data1;
  input [4:0] data2;
  output [4:0] out1;
  output [4:0] out2;
  output [4:0] out3;
  input sel, clk;
  wire   n47, N1, N2, N3, N5, N6, N7, N8, N9, N10, N11, N12, N13, N14, n200,
         n300, n4, n50, n60, n80, n90, n100, n110, n120, n130, n140, n15, n16,
         n17, n18, n19, n201, n21, n22, n23, n24, n25, n26, n27, n28, n29,
         n301, n31, n32, n33, n34, n35, n36, n37, n38, n39, n40, n42, n43, n44,
         n45, n46;
  wire   [4:0] arth_o;
  wire   [4:0] R1;
  wire   [4:0] R2;
  wire   [4:0] R3;
  wire   [4:0] R4;

  ARITH_0 U1_ARITH ( .a(data1), .b(data2), .sel(sel), .out1(arth_o) );
  COMBO U_COMBO ( .Cin1(Cin1), .Cin2(Cin2), .sel(sel), .Cout(Cout) );
  DFFPOSX1 R4_reg_3_ ( .D(N13), .CLK(clk), .Q(R4[3]) );
  DFFPOSX1 R4_reg_2_ ( .D(N12), .CLK(clk), .Q(R4[2]) );
  DFFPOSX1 R4_reg_1_ ( .D(N11), .CLK(clk), .Q(R4[1]) );
  DFFPOSX1 R4_reg_0_ ( .D(n200), .CLK(clk), .Q(R4[0]) );
  DFFPOSX1 R2_reg_4_ ( .D(n46), .CLK(clk), .Q(R2[4]) );
  DFFPOSX1 R2_reg_3_ ( .D(N1), .CLK(clk), .Q(R2[3]) );
  DFFPOSX1 R2_reg_2_ ( .D(N2), .CLK(clk), .Q(R2[2]) );
  DFFPOSX1 R2_reg_1_ ( .D(N3), .CLK(clk), .Q(R2[1]) );
  DFFPOSX1 R2_reg_0_ ( .D(n140), .CLK(clk), .Q(R2[0]) );
  DFFPOSX1 R3_reg_4_ ( .D(N9), .CLK(clk), .Q(R3[4]) );
  DFFPOSX1 R3_reg_3_ ( .D(N8), .CLK(clk), .Q(R3[3]) );
  DFFPOSX1 R3_reg_2_ ( .D(N7), .CLK(clk), .Q(R3[2]) );
  DFFPOSX1 R3_reg_1_ ( .D(N6), .CLK(clk), .Q(R3[1]) );
  DFFPOSX1 R3_reg_0_ ( .D(N5), .CLK(clk), .Q(R3[0]) );
  DFFPOSX1 R1_reg_4_ ( .D(arth_o[4]), .CLK(clk), .Q(R1[4]) );
  DFFPOSX1 R1_reg_3_ ( .D(arth_o[3]), .CLK(clk), .Q(R1[3]) );
  DFFPOSX1 R1_reg_2_ ( .D(arth_o[2]), .CLK(clk), .Q(R1[2]) );
  DFFPOSX1 R1_reg_1_ ( .D(arth_o[1]), .CLK(clk), .Q(R1[1]) );
  DFFPOSX1 R1_reg_0_ ( .D(arth_o[0]), .CLK(clk), .Q(R1[0]) );
  DFFPOSX1 R4_reg_4_ ( .D(N14), .CLK(clk), .Q(R4[4]) );
  BUFX2 U14 ( .A(N10), .Y(n200) );
  INVX1 U15 ( .A(n45), .Y(n300) );
  AND2X1 U16 ( .A(R3[4]), .B(n110), .Y(n45) );
  INVX1 U17 ( .A(n44), .Y(n4) );
  AND2X1 U18 ( .A(n60), .B(n130), .Y(n44) );
  BUFX2 U19 ( .A(n39), .Y(n50) );
  INVX1 U20 ( .A(n43), .Y(n60) );
  AND2X1 U21 ( .A(R3[3]), .B(n34), .Y(n43) );
  INVX1 U22 ( .A(n47), .Y(out3[0]) );
  OR2X1 U23 ( .A(R4[0]), .B(n33), .Y(n47) );
  INVX1 U24 ( .A(n21), .Y(n80) );
  OR2X1 U25 ( .A(n33), .B(n201), .Y(n21) );
  AND2X1 U26 ( .A(data1[4]), .B(data2[4]), .Y(n46) );
  INVX1 U27 ( .A(n46), .Y(n90) );
  AND2X1 U28 ( .A(data2[0]), .B(data1[0]), .Y(n140) );
  INVX1 U29 ( .A(n140), .Y(n100) );
  AND2X1 U30 ( .A(R3[4]), .B(R4[4]), .Y(out2[4]) );
  INVX1 U31 ( .A(out2[4]), .Y(n110) );
  OR2X1 U32 ( .A(n33), .B(n26), .Y(n27) );
  INVX1 U33 ( .A(n27), .Y(n120) );
  BUFX2 U34 ( .A(n42), .Y(n130) );
  OAI21X1 U35 ( .A(data2[0]), .B(data1[0]), .C(n100), .Y(n15) );
  INVX1 U36 ( .A(n15), .Y(N5) );
  FAX1 U37 ( .A(data1[1]), .B(data2[1]), .C(n140), .YC(n16), .YS(N6) );
  FAX1 U38 ( .A(data1[2]), .B(data2[2]), .C(n16), .YC(n17), .YS(N7) );
  OAI21X1 U39 ( .A(data1[4]), .B(data2[4]), .C(n90), .Y(n19) );
  FAX1 U40 ( .A(data1[3]), .B(data2[3]), .C(n17), .YC(n18), .YS(N8) );
  XNOR2X1 U41 ( .A(n19), .B(n18), .Y(N9) );
  INVX1 U42 ( .A(R3[0]), .Y(n33) );
  INVX1 U43 ( .A(R2[0]), .Y(n201) );
  AOI21X1 U44 ( .A(n33), .B(n201), .C(n80), .Y(N10) );
  FAX1 U45 ( .A(R2[1]), .B(R3[1]), .C(n80), .YC(n22), .YS(N11) );
  FAX1 U46 ( .A(R2[2]), .B(R3[2]), .C(n22), .YC(n23), .YS(N12) );
  INVX1 U47 ( .A(R3[4]), .Y(n32) );
  FAX1 U48 ( .A(R2[3]), .B(R3[3]), .C(n23), .YC(n24), .YS(N13) );
  HAX1 U49 ( .A(n24), .B(R2[4]), .YS(n25) );
  MUX2X1 U50 ( .B(n32), .A(R3[4]), .S(n25), .Y(N14) );
  INVX1 U51 ( .A(R1[0]), .Y(n26) );
  AOI21X1 U52 ( .A(n33), .B(n26), .C(n120), .Y(out1[0]) );
  FAX1 U53 ( .A(R1[1]), .B(R3[1]), .C(n120), .YC(n28), .YS(out1[1]) );
  FAX1 U54 ( .A(R1[2]), .B(R3[2]), .C(n28), .YC(n29), .YS(out1[2]) );
  FAX1 U55 ( .A(R1[3]), .B(R3[3]), .C(n29), .YC(n301), .YS(out1[3]) );
  HAX1 U56 ( .A(R1[4]), .B(n301), .YS(n31) );
  MUX2X1 U57 ( .B(n32), .A(R3[4]), .S(n31), .Y(out1[4]) );
  AND2X1 U58 ( .A(R4[3]), .B(R3[3]), .Y(out2[3]) );
  INVX1 U59 ( .A(R4[3]), .Y(n34) );
  INVX1 U60 ( .A(R4[2]), .Y(n35) );
  INVX1 U61 ( .A(R4[1]), .Y(n38) );
  AOI21X1 U62 ( .A(R3[1]), .B(n38), .C(out3[0]), .Y(n39) );
  INVX1 U63 ( .A(n50), .Y(n36) );
  AOI21X1 U64 ( .A(n35), .B(R3[2]), .C(n36), .Y(n42) );
  HAX1 U65 ( .A(n60), .B(n130), .YS(out3[3]) );
  AND2X1 U66 ( .A(R4[2]), .B(R3[2]), .Y(out2[2]) );
  AND2X1 U67 ( .A(n35), .B(R3[2]), .Y(n37) );
  AOI21X1 U68 ( .A(n37), .B(n36), .C(n130), .Y(out3[2]) );
  AND2X1 U69 ( .A(R4[1]), .B(R3[1]), .Y(out2[1]) );
  AND2X1 U70 ( .A(n38), .B(R3[1]), .Y(n40) );
  AOI21X1 U71 ( .A(n40), .B(out3[0]), .C(n50), .Y(out3[1]) );
  AND2X1 U72 ( .A(R4[0]), .B(R3[0]), .Y(out2[0]) );
  XNOR2X1 U73 ( .A(n300), .B(n4), .Y(out3[4]) );
  AND2X1 U74 ( .A(data2[3]), .B(data1[3]), .Y(N1) );
  AND2X1 U75 ( .A(data2[2]), .B(data1[2]), .Y(N2) );
  AND2X1 U76 ( .A(data2[1]), .B(data1[1]), .Y(N3) );
endmodule


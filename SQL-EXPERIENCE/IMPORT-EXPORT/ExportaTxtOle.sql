/*
    OBJETIVO: Stored procedure para exportar uma string para arquivo em disco
              utilizando OLE Automation (Scripting.FileSystemObject).
    PROJETO: mssqlserver-solution-explorer
    FONTE:   https://www.dirceuresende.com/blog/sql-server-como-exportar-dados-do-banco-para-arquivo-texto-clr-ole-bcp/

    EXEMPLO DE USO — 01: Exportando uma string para arquivo com OLE Automation:
    --DECLARE @Texto VARCHAR(MAX) = 'Teste
    --de arquivo
    --com quebra
    --de
    --linhas
    --'

    EXEMPLO DE USO - 02:
    --EXEC Management.[sp_Escreve_Arquivo_FSO] 
    --    @String = '<nfeProc xmlns=http://www.portalfiscal.inf.br/nfe versao=3.10><NFe xmlns=http://www.portalfiscal.inf.br/nfe><infNFe Id=NFe42170285789782000142550050003807161000479510 versao=3.10><ide><cUF>42</cUF><cNF>00047951</cNF><natOp>SAIDA TRANSF COMERCIALIZACAO</natOp><indPag>0</indPag><mod>55</mod><serie>5</serie><nNF>380716</nNF><dhEmi>2017-02-20T09:33:00-02:00</dhEmi><dhSaiEnt>2017-02-20T09:33:00-02:00</dhSaiEnt><tpNF>1</tpNF><idDest>1</idDest><cMunFG>4214805</cMunFG><tpImp>1</tpImp><tpEmis>1</tpEmis><cDV>0</cDV><tpAmb>1</tpAmb><finNFe>1</finNFe><indFinal>0</indFinal><indPres>1</indPres><procEmi>0</procEmi><verProc>YOUR_DATABASE V3.10</verProc></ide><emit><CNPJ>85789782000142</CNPJ><xNome>COOPERATIVA REG AGROP VALE ITAJAI</xNome><xFant>CRAVIL</xFant><enderEmit><xLgr>BR 470 KM 141</xLgr><nro>6900</nro><xBairro>CANTA GALO</xBairro><cMun>4214805</cMun><xMun>RIO DO SUL</xMun><UF>SC</UF><CEP>89163020</CEP><cPais>1058</cPais><xPais>BRASIL</xPais><fone>04735313000</fone></enderEmit><IE>250170531</IE><IM>16834</IM><CRT>3</CRT></emit><dest><CNPJ>85789782001203</CNPJ><xNome>COOP REG AGROPEC VALE DO ITAJAI POUSO REDONDO</xNome><enderDest><xLgr>RUA 23 DE JULHO</xLgr><nro>100</nro><xBairro>CENTRO</xBairro><cMun>4213708</cMun><xMun>POUSO REDONDO</xMun><UF>SC</UF><CEP>89172000</CEP><cPais>1058</cPais><xPais>BRASIL</xPais><fone>4735451764</fone></enderDest><indIEDest>1</indIEDest><IE>250160030</IE></dest><det nItem=1><prod><cProd>38357</cProd><cEAN>7898917108307</cEAN><xProd>BOBINA FREEZER STARPLAST C 100 5 KG</xProd><NCM>39232190</NCM><CEST>1500400</CEST><CFOP>5152</CFOP><uCom>UN</uCom><qCom>2.0000</qCom><vUnCom>3.0800</vUnCom><vProd>6.16</vProd><cEANTrib>7898917108307</cEANTrib><uTrib>UN</uTrib><qTrib>2.0000</qTrib><vUnTrib>3.0800</vUnTrib><indTot>1</indTot></prod><imposto><ICMS><ICMS51><orig>0</orig><CST>51</CST></ICMS51></ICMS><IPI><cEnq>999</cEnq><IPINT><CST>53</CST></IPINT></IPI><PIS><PISNT><CST>07</CST></PISNT></PIS><COFINS><COFINSNT><CST>07</CST></COFINSNT></COFINS></imposto></det><det nItem=2><prod><cProd>9016</cProd><cEAN>7891200011704</cEAN><xProd>COLA CASCOLA FLEXITE USO GERAL 50 GR</xProd><NCM>32141010</NCM><CFOP>5152</CFOP><uCom>CR</uCom><qCom>1.0000</qCom><vUnCom>3.4900</vUnCom><vProd>3.49</vProd><cEANTrib>7891200011704</cEANTrib><uTrib>CRT</uTrib><qTrib>1.0000</qTrib><vUnTrib>3.4900</vUnTrib><indTot>1</indTot></prod><imposto><ICMS><ICMS51><orig>0</orig><CST>51</CST></ICMS51></ICMS><IPI><cEnq>999</cEnq><IPINT><CST>53</CST></IPINT></IPI><PIS><PISNT><CST>07</CST></PISNT></PIS><COFINS><COFINSNT><CST>07</CST></COFINSNT></COFINS></imposto></det><det nItem=3><prod><cProd>8761</cProd><cEAN>7891200234257</cEAN><xProd>COLA SUPER BONDER PRECISAO LOCTITE 5 GR</xProd><NCM>35061010</NCM><CFOP>5152</CFOP><uCom>CR</uCom><qCom>1.0000</qCom><vUnCom>3.5800</vUnCom><vProd>3.58</vProd><cEANTrib>7891200234257</cEANTrib><uTrib>CR</uTrib><qTrib>1.0000</qTrib><vUnTrib>3.5800</vUnTrib><indTot>1</indTot></prod><imposto><ICMS><ICMS51><orig>0</orig><CST>51</CST></ICMS51></ICMS><IPI><cEnq>999</cEnq><IPINT><CST>53</CST></IPINT></IPI><PIS><PISNT><CST>07</CST></PISNT></PIS><COFINS><COFINSNT><CST>07</CST></COFINSNT></COFINS></imposto></det><det nItem=4><prod><cProd>111324</cProd><cEAN>7896098900253</cEAN><xProd>DETERG LIQ YPE CLEAR 500 ML</xProd><NCM>34022000</NCM><CEST>1100500</CEST><CFOP>5409</CFOP><uCom>FRS</uCom><qCom>24.0000</qCom><vUnCom>1.1700</vUnCom><vProd>28.08</vProd><cEANTrib>7896098900253</cEANTrib><uTrib>FRS</uTrib><qTrib>24.0000</qTrib><vUnTrib>1.1700</vUnTrib><indTot>1</indTot></prod><imposto><ICMS><ICMS51><orig>0</orig><CST>51</CST></ICMS51></ICMS><IPI><cEnq>999</cEnq><IPINT><CST>53</CST></IPINT></IPI><PIS><PISNT><CST>07</CST></PISNT></PIS><COFINS><COFINSNT><CST>07</CST></COFINSNT></COFINS></imposto></det><det nItem=5><prod><cProd>42091</cProd><cEAN>7896451844828</cEAN><xProd>DUCHA LORENZETTI BELLA DUCHA 4T 220 6800 BCO</xProd><NCM>85161000</NCM><CEST>1200200</CEST><CFOP>5409</CFOP><uCom>IND</uCom><qCom>1.0000</qCom><vUnCom>28.6600</vUnCom><vProd>28.66</vProd><cEANTrib>7896451844828</cEANTrib><uTrib>IND</uTrib><qTrib>1.0000</qTrib><vUnTrib>28.6600</vUnTrib><indTot>1</indTot></prod><imposto><ICMS><ICMS51><orig>0</orig><CST>51</CST></ICMS51></ICMS><IPI><cEnq>999</cEnq><IPINT><CST>53</CST></IPINT></IPI><PIS><PISNT><CST>07</CST></PISNT></PIS><COFINS><COFINSNT><CST>07</CST></COFINSNT></COFINS></imposto></det><det nItem=6><prod><cProd>274</cProd><cEAN>7896027080001</cEAN><xProd>FUMIGANTE JIMO GAS ESTOJO C 2 TUBOS DE 35 GR</xProd><NCM>38089119</NCM><CFOP>5152</CFOP><uCom>UND</uCom><qCom>1.0000</qCom><vUnCom>5.8500</vUnCom><vProd>5.85</vProd><cEANTrib>7896027080001</cEANTrib><uTrib>UND</uTrib><qTrib>1.0000</qTrib><vUnTrib>5.8500</vUnTrib><indTot>1</indTot></prod><imposto><ICMS><ICMS51><orig>0</orig><CST>51</CST></ICMS51></ICMS><IPI><cEnq>999</cEnq><IPINT><CST>53</CST></IPINT></IPI><PIS><PISNT><CST>07</CST></PISNT></PIS><COFINS><COFINSNT><CST>07</CST></COFINSNT></COFINS></imposto></det><det nItem=7><prod><cProd>5814</cProd><cEAN/><xProd>ISQUEIRO BIC MAXI GRAPHIC UN</xProd><NCM>96131000</NCM><CFOP>5152</CFOP><uCom>CR</uCom><qCom>12.0000</qCom><vUnCom>2.0600</vUnCom><vProd>24.72</vProd><cEANTrib/><uTrib>CR</uTrib><qTrib>12.0000</qTrib><vUnTrib>2.0600</vUnTrib><indTot>1</indTot></prod><imposto><ICMS><ICMS51><orig>0</orig><CST>51</CST></ICMS51></ICMS><IPI><cEnq>999</cEnq><IPINT><CST>53</CST></IPINT></IPI><PIS><PISNT><CST>07</CST></PISNT></PIS><COFINS><COFINSNT><CST>07</CST></COFINSNT></COFINS></imposto></det><det nItem=8><prod><cProd>42978</cProd><cEAN>7897079068252</cEAN><xProd>LAMPADA TASCHIBRA LED TKL 1100 LUM 11W 4000K BIV</xProd><NCM>85437099</NCM><CEST>0900500</CEST><CFOP>5152</CFOP><uCom>UND</uCom><qCom>2.0000</qCom><vUnCom>11.1700</vUnCom><vProd>22.34</vProd><cEANTrib>7897079068252</cEANTrib><uTrib>UND</uTrib><qTrib>2.0000</qTrib><vUnTrib>11.1700</vUnTrib><indTot>1</indTot></prod><imposto><ICMS><ICMS51><orig>0</orig><CST>51</CST></ICMS51></ICMS><IPI><cEnq>999</cEnq><IPINT><CST>53</CST></IPINT></IPI><PIS><PISNT><CST>07</CST></PISNT></PIS><COFINS><COFINSNT><CST>07</CST></COFINSNT></COFINS></imposto></det><det nItem=9><prod><cProd>42979</cProd><cEAN>7897079065589</cEAN><xProd>LAMPADA TASCHIBRA LED TKL 900 LUM 9W 6500K BIV UND</xProd><NCM>85437099</NCM><CEST>0900500</CEST><CFOP>5152</CFOP><uCom>UND</uCom><qCom>2.0000</qCom><vUnCom>8.2500</vUnCom><vProd>16.50</vProd><cEANTrib>7897079065589</cEANTrib><uTrib>UND</uTrib><qTrib>2.0000</qTrib><vUnTrib>8.2500</vUnTrib><indTot>1</indTot></prod><imposto><ICMS><ICMS51><orig>0</orig><CST>51</CST></ICMS51></ICMS><IPI><cEnq>999</cEnq><IPINT><CST>53</CST></IPINT></IPI><PIS><PISNT><CST>07</CST></PISNT></PIS><COFINS><COFINSNT><CST>07</CST></COFINSNT></COFINS></imposto></det><det nItem=10><prod><cProd>13765</cProd><cEAN>7891150016750</cEAN><xProd>LAVA ROUPA BRILHANTE 1 KG</xProd><NCM>34022000</NCM><CEST>1100400</CEST><CFOP>5409</CFOP><uCom>Pct</uCom><qCom>16.0000</qCom><vUnCom>4.6500</vUnCom><vProd>74.40</vProd><cEANTrib>7891150016750</cEANTrib><uTrib>Pct</uTrib><qTrib>16.0000</qTrib><vUnTrib>4.6500</vUnTrib><indTot>1</indTot></prod><imposto><ICMS><ICMS51><orig>0</orig><CST>51</CST></ICMS51></ICMS><IPI><cEnq>999</cEnq><IPINT><CST>53</CST></IPINT></IPI><PIS><PISNT><CST>07</CST></PISNT></PIS><COFINS><COFINSNT><CST>07</CST></COFINSNT></COFINS></imposto></det><det nItem=11><prod><cProd>43890</cProd><cEAN>7898906901926</cEAN><xProd>MATA BARATAS CITROMAX GEL 10 GR</xProd><NCM>38089119</NCM><CFOP>5152</CFOP><uCom>UND</uCom><qCom>2.0000</qCom><vUnCom>4.2200</vUnCom><vProd>8.44</vProd><cEANTrib>7898906901926</cEANTrib><uTrib>UND</uTrib><qTrib>2.0000</qTrib><vUnTrib>4.2200</vUnTrib><indTot>1</indTot></prod><imposto><ICMS><ICMS51><orig>0</orig><CST>51</CST></ICMS51></ICMS><IPI><cEnq>999</cEnq><IPINT><CST>53</CST></IPINT></IPI><PIS><PISNT><CST>07</CST></PISNT></PIS><COFINS><COFINSNT><CST>07</CST></COFINSNT></COFINS></imposto></det><det nItem=12><prod><cProd>32629</cProd><cEAN>7896009718113</cEAN><xProd>PILHA RAYOVAC PEQ C 4 UN</xProd><NCM>85061020</NCM><CFOP>5152</CFOP><uCom>CR</uCom><qCom>4.0000</qCom><vUnCom>2.0700</vUnCom><vProd>8.28</vProd><cEANTrib>7896009718113</cEANTrib><uTrib>CR</uTrib><qTrib>4.0000</qTrib><vUnTrib>2.0700</vUnTrib><indTot>1</indTot></prod><imposto><ICMS><ICMS51><orig>0</orig><CST>51</CST></ICMS51></ICMS><IPI><cEnq>999</cEnq><IPINT><CST>53</CST></IPINT></IPI><PIS><PISNT><CST>07</CST></PISNT></PIS><COFINS><COFINSNT><CST>07</CST></COFINSNT></COFINS></imposto></det><det nItem=13><prod><cProd>13410</cProd><cEAN>7899320501808</cEAN><xProd>RODO ALTERNATIVA 50 CM CABO MADEIRA</xProd><NCM>96039000</NCM><CFOP>5152</CFOP><uCom>UN</uCom><qCom>1.0000</qCom><vUnCom>10.2900</vUnCom><vProd>10.29</vProd><cEANTrib>7899320501808</cEANTrib><uTrib>UN</uTrib><qTrib>1.0000</qTrib><vUnTrib>10.2900</vUnTrib><indTot>1</indTot></prod><imposto><ICMS><ICMS51><orig>0</orig><CST>51</CST></ICMS51></ICMS><IPI><cEnq>999</cEnq><IPINT><CST>53</CST></IPINT></IPI><PIS><PISNT><CST>07</CST></PISNT></PIS><COFINS><COFINSNT><CST>07</CST></COFINSNT></COFINS></imposto></det><det nItem=14><prod><cProd>38169</cProd><cEAN>7899320501785</cEAN><xProd>RODO DE ESPUMA ALTERNATIVA</xProd><NCM>96039000</NCM><CFOP>5152</CFOP><uCom>UN</uCom><qCom>1.0000</qCom><vUnCom>6.2700</vUnCom><vProd>6.27</vProd><cEANTrib>7899320501785</cEANTrib><uTrib>UN</uTrib><qTrib>1.0000</qTrib><vUnTrib>6.2700</vUnTrib><indTot>1</indTot></prod><imposto><ICMS><ICMS51><orig>0</orig><CST>51</CST></ICMS51></ICMS><IPI><cEnq>999</cEnq><IPINT><CST>53</CST></IPINT></IPI><PIS><PISNT><CST>07</CST></PISNT></PIS><COFINS><COFINSNT><CST>07</CST></COFINSNT></COFINS></imposto></det><det nItem=15><prod><cProd>16514</cProd><cEAN>4005808806423</cEAN><xProd>SABONETE NIVEA AVEIA 90 GR</xProd><NCM>34011190</NCM><CEST>2003400</CEST><CFOP>5409</CFOP><uCom>Pct</uCom><qCom>12.0000</qCom><vUnCom>1.0200</vUnCom><vProd>12.24</vProd><cEANTrib>4005808806423</cEANTrib><uTrib>0</uTrib><qTrib>12.0000</qTrib><vUnTrib>1.0200</vUnTrib><indTot>1</indTot></prod><imposto><ICMS><ICMS51><orig>0</orig><CST>51</CST></ICMS51></ICMS><IPI><cEnq>999</cEnq><IPINT><CST>53</CST></IPINT></IPI><PIS><PISNT><CST>07</CST></PISNT></PIS><COFINS><COFINSNT><CST>07</CST></COFINSNT></COFINS></imposto></det><det nItem=16><prod><cProd>16601</cProd><cEAN>7891109146378</cEAN><xProd>SANDALIA HAVAIANA AZUL N 37 38</xProd><NCM>64022000</NCM><CFOP>5152</CFOP><uCom>PAR</uCom><qCom>1.0000</qCom><vUnCom>5.7700</vUnCom><vProd>5.77</vProd><cEANTrib>7891109146378</cEANTrib><uTrib>0</uTrib><qTrib>1.0000</qTrib><vUnTrib>5.7700</vUnTrib><indTot>1</indTot></prod><imposto><ICMS><ICMS51><orig>0</orig><CST>51</CST></ICMS51></ICMS><IPI><cEnq>999</cEnq><IPINT><CST>53</CST></IPINT></IPI><PIS><PISNT><CST>07</CST></PISNT></PIS><COFINS><COFINSNT><CST>07</CST></COFINSNT></COFINS></imposto></det><det nItem=17><prod><cProd>16593</cProd><cEAN>7891109146408</cEAN><xProd>SANDALIA HAVAIANA AZUL N 43 44</xProd><NCM>64022000</NCM><CFOP>5152</CFOP><uCom>PAR</uCom><qCom>1.0000</qCom><vUnCom>5.7800</vUnCom><vProd>5.78</vProd><cEANTrib>7891109146408</cEANTrib><uTrib>0</uTrib><qTrib>1.0000</qTrib><vUnTrib>5.7800</vUnTrib><indTot>1</indTot></prod><imposto><ICMS><ICMS51><orig>0</orig><CST>51</CST></ICMS51></ICMS><IPI><cEnq>999</cEnq><IPINT><CST>53</CST></IPINT></IPI><PIS><PISNT><CST>07</CST></PISNT></PIS><COFINS><COFINSNT><CST>07</CST></COFINSNT></COFINS></imposto></det><det nItem=18><prod><cProd>48331</cProd><cEAN>7909171616818</cEAN><xProd>SANDALIA IPANEMA ANATOMICA SOFT AZUL N 37</xProd><NCM>64022000</NCM><CFOP>5152</CFOP><uCom>PAR</uCom><qCom>1.0000</qCom><vUnCom>8.4000</vUnCom><vProd>8.40</vProd><cEANTrib>7909171616818</cEANTrib><uTrib>PAR</uTrib><qTrib>1.0000</qTrib><vUnTrib>8.4000</vUnTrib><indTot>1</indTot></prod><imposto><ICMS><ICMS51><orig>0</orig><CST>51</CST></ICMS51></ICMS><IPI><cEnq>999</cEnq><IPINT><CST>53</CST></IPINT></IPI><PIS><PISNT><CST>07</CST></PISNT></PIS><COFINS><COFINSNT><CST>07</CST></COFINSNT></COFINS></imposto></det><det nItem=19><prod><cProd>48333</cProd><cEAN>7909171616979</cEAN><xProd>SANDALIA IPANEMA ANATOMICA SOFT BEGE N 35</xProd><NCM>64022000</NCM><CFOP>5152</CFOP><uCom>PAR</uCom><qCom>1.0000</qCom><vUnCom>8.4000</vUnCom><vProd>8.40</vProd><cEANTrib>7909171616979</cEANTrib><uTrib>PAR</uTrib><qTrib>1.0000</qTrib><vUnTrib>8.4000</vUnTrib><indTot>1</indTot></prod><imposto><ICMS><ICMS51><orig>0</orig><CST>51</CST></ICMS51></ICMS><IPI><cEnq>999</cEnq><IPINT><CST>53</CST></IPINT></IPI><PIS><PISNT><CST>07</CST></PISNT></PIS><COFINS><COFINSNT><CST>07</CST></COFINSNT></COFINS></imposto></det><det nItem=20><prod><cProd>48293</cProd><cEAN>7890244999115</cEAN><xProd>SANDALIA IPANEMA ANATOMICA SURF PRETO N 41 42</xProd><NCM>64022000</NCM><CFOP>5152</CFOP><uCom>PAR</uCom><qCom>1.0000</qCom><vUnCom>7.3800</vUnCom><vProd>7.38</vProd><cEANTrib>7890244999115</cEANTrib><uTrib>PAR</uTrib><qTrib>1.0000</qTrib><vUnTrib>7.3800</vUnTrib><indTot>1</indTot></prod><imposto><ICMS><ICMS51><orig>0</orig><CST>51</CST></ICMS51></ICMS><IPI><cEnq>999</cEnq><IPINT><CST>53</CST></IPINT></IPI><PIS><PISNT><CST>07</CST></PISNT></PIS><COFINS><COFINSNT><CST>07</CST></COFINSNT></COFINS></imposto></det><det nItem=21><prod><cProd>48348</cProd><cEAN>7909171841036</cEAN><xProd>SANDALIA IPANEMA INF BARBIE STYLE LILAS N 25 26</xProd><NCM>64022000</NCM><CFOP>5152</CFOP><uCom>PAR</uCom><qCom>1.0000</qCom><vUnCom>10.7300</vUnCom><vProd>10.73</vProd><cEANTrib>7909171841036</cEANTrib><uTrib>PAR</uTrib><qTrib>1.0000</qTrib><vUnTrib>10.7300</vUnTrib><indTot>1</indTot></prod><imposto><ICMS><ICMS51><orig>0</orig><CST>51</CST></ICMS51></ICMS><IPI><cEnq>999</cEnq><IPINT><CST>53</CST></IPINT></IPI><PIS><PISNT><CST>07</CST></PISNT></PIS><COFINS><COFINSNT><CST>07</CST></COFINSNT></COFINS></imposto></det><det nItem=22><prod><cProd>19000</cProd><cEAN>7891022100143</cEAN><xProd>SAPONACEO CREMOSO SAPOLIO RADIUM LIMAO 300 ML</xProd><NCM>34054000</NCM><CFOP>5152</CFOP><uCom>FRS</uCom><qCom>1.0000</qCom><vUnCom>3.0200</vUnCom><vProd>3.02</vProd><cEANTrib>7891022100143</cEANTrib><uTrib>FRS</uTrib><qTrib>1.0000</qTrib><vUnTrib>3.0200</vUnTrib><indTot>1</indTot></prod><imposto><ICMS><ICMS51><orig>0</orig><CST>51</CST></ICMS51></ICMS><IPI><cEnq>999</cEnq><IPINT><CST>53</CST></IPINT></IPI><PIS><PISNT><CST>07</CST></PISNT></PIS><COFINS><COFINSNT><CST>07</CST></COFINSNT></COFINS></imposto></det><det nItem=23><prod><cProd>40793</cProd><cEAN>7891112002388</cEAN><xProd>TESOURA TRAMONTINA BORDADO INOX 5 SUPERCORT</xProd><NCM>82130000</NCM><CEST>0801800</CEST><CFOP>5409</CFOP><uCom>UN</uCom><qCom>1.0000</qCom><vUnCom>8.8300</vUnCom><vProd>8.83</vProd><cEANTrib>7891112002388</cEANTrib><uTrib>UN</uTrib><qTrib>1.0000</qTrib><vUnTrib>8.8300</vUnTrib><indTot>1</indTot></prod><imposto><ICMS><ICMS51><orig>0</orig><CST>51</CST></ICMS51></ICMS><IPI><cEnq>999</cEnq><IPINT><CST>53</CST></IPINT></IPI><PIS><PISNT><CST>07</CST></PISNT></PIS><COFINS><COFINSNT><CST>07</CST></COFINSNT></COFINS></imposto></det><det nItem=24><prod><cProd>118606</cProd><cEAN>7891055010983</cEAN><xProd>VASSOURA CONDOR VARRE PRATICA NYLON V 7</xProd><NCM>96039000</NCM><CFOP>5152</CFOP><uCom>UN</uCom><qCom>4.0000</qCom><vUnCom>10.6900</vUnCom><vProd>42.76</vProd><cEANTrib>7891055010983</cEANTrib><uTrib>UN</uTrib><qTrib>4.0000</qTrib><vUnTrib>10.6900</vUnTrib><indTot>1</indTot></prod><imposto><ICMS><ICMS51><orig>0</orig><CST>51</CST></ICMS51></ICMS><IPI><cEnq>999</cEnq><IPINT><CST>53</CST></IPINT></IPI><PIS><PISNT><CST>07</CST></PISNT></PIS><COFINS><COFINSNT><CST>07</CST></COFINSNT></COFINS></imposto></det><det nItem=25><prod><cProd>30724</cProd><cEAN>10307243</cEAN><xProd>VASSOURA PALHA UN</xProd><NCM>96031000</NCM><CFOP>5152</CFOP><uCom>UN</uCom><qCom>12.0000</qCom><vUnCom>16.6200</vUnCom><vProd>199.44</vProd><cEANTrib>10307243</cEANTrib><uTrib>0</uTrib><qTrib>12.0000</qTrib><vUnTrib>16.6200</vUnTrib><indTot>1</indTot></prod><imposto><ICMS><ICMS51><orig>0</orig><CST>51</CST></ICMS51></ICMS><IPI><cEnq>999</cEnq><IPINT><CST>53</CST></IPINT></IPI><PIS><PISNT><CST>07</CST></PISNT></PIS><COFINS><COFINSNT><CST>07</CST></COFINSNT></COFINS></imposto></det><total><ICMSTot><vBC>0.00</vBC><vICMS>0.00</vICMS><vICMSDeson>0</vICMSDeson><vBCST>0.00</vBCST><vST>0.00</vST><vProd>559.81</vProd><vFrete>0</vFrete><vSeg>0</vSeg><vDesc>0.00</vDesc><vII>0.00</vII><vIPI>0.00</vIPI><vPIS>0.00</vPIS><vCOFINS>0.00</vCOFINS><vOutro>0.00</vOutro><vNF>559.81</vNF></ICMSTot><retTrib/></total><transp><modFrete>1</modFrete><transporta><CNPJ>01749970000157</CNPJ><xNome>TRANSPORTES JR27 EIRELI</xNome><IE>253468930</IE><xEnder>RODOVIA BR 470</xEnder><xMun>RIO DO SUL</xMun><UF>SC</UF></transporta><veicTransp><placa>LYM1326</placa><UF>SC</UF></veicTransp><vol><marca>SEM MARCA</marca><pesoL>45.068</pesoL><pesoB>47.576</pesoB></vol></transp><infAdic><infCpl>FRETE 1 73 FRETE 1 73 CARGA PED REPRES LOTE 73956 ICMS DIFERIDO CFE DISPOSTO NO ANEXO III DO ART 8 INCISO III DEC 2870 01 DISPENSADO DA EMISSAO DE CONHECIMENTO DE TRANSPORTE DE ACORDO COM O ART 67 ANEXO 5 DO RICMS SC DECRETO 2 870 NR CONTROLE 47951 NR NOTA 380716 PEDIDO DE VENDA 1 CARGA PED REPRES LOTE 73956 NOME FANTASIA POUSO REDONDO USUARIO DOUGLASAP</infCpl></infAdic></infNFe><Signature xmlns=http://www.w3.org/2000/09/xmldsig#><SignedInfo><CanonicalizationMethod Algorithm=http://www.w3.org/TR/2001/REC-xml-c14n-20010315/><SignatureMethod Algorithm=http://www.w3.org/2000/09/xmldsig#rsa-sha1/><Reference URI=#NFe42170285789782000142550050003807161000479510><Transforms><Transform Algorithm=http://www.w3.org/2000/09/xmldsig#enveloped-signature/><Transform Algorithm=http://www.w3.org/TR/2001/REC-xml-c14n-20010315/></Transforms><DigestMethod Algorithm=http://www.w3.org/2000/09/xmldsig#sha1/><DigestValue>LKLyf3lrObBwD3rfm3nm9lUvp7A=</DigestValue></Reference></SignedInfo><SignatureValue>FiLCVQK5bOeU7Xym35pJOn+ccTFMqoaAOh0KojYMMCphlsDLTBOW8JDsQFFj8zqyKtCh1nVeE/4rcPd4S2NgeSIx21Art2SVhnOcRSSjciWUaT/EfmlcLWiu5LaLiwxvvzgJswDYbBbXU8+6oLT7h/JJhpN/F7d17rpgeDHQg6cH7yMTuCK3rBwGxDb+QLXc55IfsDP888UBUYEdxGWracM7m0Ph4JHMEh+AlHhl5Ta8gSIYKhxQrIXaK4Bw15zXuyHn2BLuEmDwzXafbK14WE1vItC9s48D4xlr+E7pPJ3GfDZ2gvmgeRqc5+DyQ+QsSV+3SVwBMJUO/WVPsLxsug==</SignatureValue><KeyInfo><X509Data><X509Certificate>MIIIUTCCBjmgAwIBAgIQZvUcmNdCNeElsvQBmF4iTTANBgkqhkiG9w0BAQsFADB4MQswCQYDVQQGEwJCUjETMBEGA1UEChMKSUNQLUJyYXNpbDE2MDQGA1UECxMtU2VjcmV0YXJpYSBkYSBSZWNlaXRhIEZlZGVyYWwgZG8gQnJhc2lsIC0gUkZCMRwwGgYDVQQDExNBQyBDZXJ0aXNpZ24gUkZCIEc0MB4XDTE2MDYwMjAwMDAwMFoXDTE3MDYwMTIzNTk1OVowggECMQswCQYDVQQGEwJCUjETMBEGA1UEChQKSUNQLUJyYXNpbDELMAkGA1UECBMCU0MxEzARBgNVBAcUClJJTyBETyBTVUwxNjA0BgNVBAsULVNlY3JldGFyaWEgZGEgUmVjZWl0YSBGZWRlcmFsIGRvIEJyYXNpbCAtIFJGQjEWMBQGA1UECxQNUkZCIGUtQ05QSiBBMTEiMCAGA1UECxQZQXV0ZW50aWNhZG8gcG9yIEFSIENOQiBDRjFIMEYGA1UEAxM/Q09PUEVSQVRJVkEgUkVHSU9OQUwgQUdST1BFQ1VBUklBIFZBTEUgRE8gSVRBSkFJOjg1Nzg5NzgyMDAwMTQyMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAxBozLzxWgaXl0hv5aT/OK0CcXbCSVR1SCzxneIYzOyEk02yiWGFxEArqGoKt30vz2hdsnqLl9YTq1N+RFMZBOGLvPjiTmFIiBxesGtv9jk8EQQ0oGpGbIRoG+r4Uz3im4EyJaagho6OkQhESyNf8pjj7AR1rPxYK4wYWQSeUEdWR1ACEIs4QPR5VtkdbG0167EcqVvpZ9R/ONUQgLm4Ds9AIW/VnbfLTQFiRogcH0hLtxMn93a3BcvkUbFs+kq6QoPkwGOd8nlHEbql6ZhN6htw/zQSvwPI2VkwQWmOQEpfnnnEQ/0FmGvw/J8pTnhsmS/AGeejRxWwTLgv4op68dwIDAQABo4IDSTCCA0Uwga4GA1UdEQSBpjCBo6A9BgVgTAEDBKA0BDIyODAyMTk0NzA2ODk4OTM5OTA0MDAwMDAwMDAwMDAwMDAwMDAwMDUyNjM5NTZTU1BTQ6AWBgVgTAEDAqANBAtIQVJSWSBET1JPV6AZBgVgTAEDA6AQBA44NTc4OTc4MjAwMDE0MqAXBgVgTAEDB6AOBAwwMDAwMDAwMDAwMDCBFmNvbnRhYmlsQGNyYXZpbC5jb20uYnIwCQYDVR0TBAIwADAfBgNVHSMEGDAWgBQukerWbeWyWYLcOIUpdjQWVjzQPjAOBgNVHQ8BAf8EBAMCBeAwfwYDVR0gBHgwdjB0BgZgTAECAQwwajBoBggrBgEFBQcCARZcaHR0cDovL2ljcC1icmFzaWwuY2VydGlzaWduLmNvbS5ici9yZXBvc2l0b3Jpby9kcGMvQUNfQ2VydGlzaWduX1JGQi9EUENfQUNfQ2VydGlzaWduX1JGQi5wZGYwggEWBgNVHR8EggENMIIBCTBXoFWgU4ZRaHR0cDovL2ljcC1icmFzaWwuY2VydGlzaWduLmNvbS5ici9yZXBvc2l0b3Jpby9sY3IvQUNDZXJ0aXNpZ25SRkJHNC9MYXRlc3RDUkwuY3JsMFagVKBShlBodHRwOi8vaWNwLWJyYXNpbC5vdXRyYWxjci5jb20uYnIvcmVwb3NpdG9yaW8vbGNyL0FDQ2VydGlzaWduUkZCRzQvTGF0ZXN0Q1JMLmNybDBWoFSgUoZQaHR0cDovL3JlcG9zaXRvcmlvLmljcGJyYXNpbC5nb3YuYnIvbGNyL0NlcnRpc2lnbi9BQ0NlcnRpc2lnblJGQkc0L0xhdGVzdENSTC5jcmwwHQYDVR0lBBYwFAYIKwYBBQUHAwIGCCsGAQUFBwMEMIGbBggrBgEFBQcBAQSBjjCBizBfBggrBgEFBQcwAoZTaHR0cDovL2ljcC1icmFzaWwuY2VydGlzaWduLmNvbS5ici9yZXBvc2l0b3Jpby9jZXJ0aWZpY2Fkb3MvQUNfQ2VydGlzaWduX1JGQl9HNC5wN2MwKAYIKwYBBQUHMAGGHGh0dHA6Ly9vY3NwLmNlcnRpc2lnbi5jb20uYnIwDQYJKoZIhvcNAQELBQADggIBAMU7B6XjIHoiTIf9ZVFSoH/z95n4ObLhHv7MVi2NzO1/AnBtNKg3oXMt10vmYw0+Oaj6HPoyBo3uTWtFqq4ae9sKh/vLNo6kBFiJc3q5J25mNXzf58qvBGrlzmT56mGh8rDs18RoVv/w+/6iFgGtfQq7VETxhyToiDU9h6W6ipaVMDKHpIP3AZdVw6n4Wd2tbiw917kZvVVn2d6/l1PHx1UMpAEEFeyuiJWOjxMA5Dc7x1yoeGynbc37l7sNy43suJOUlE25cxJ9OajNJ2gxx2hWIYBcoF4TpJr2vQEqr6VFd9g/81TGabHe0cZMn4UcZtRM0iE1bqHJToTDccz16q5Z5HyxGM6WI9d/sOvVU2epEubLNuE3JUTqAwR8wSDPY4J8FdJbOZYX8VJwrnCWehy32N5o+15zRGAsyNBBLmk+pfSozrFBEdg4QPr5+bR/X1eyyLKJI+c37rNWdvx+KqcW3L9KBvfV3ak3WY/YsGH7SPc9NvMifTpDW0VpWPybBRIZPTt1ytGDfymvbASiUihSgni8rBpgbv2oBneJniMNO+Rm71x5YI0Y/OKpDOLQBSI9VQkfanYn8zOiyPrpgFVh21UL5ysVaNOpHntcxNs6YBMXuHw/toMN1F1VJCKX51iYLTmqyXWQchlxNZXDgFJOG7D8m9u8xF4cf2KY/naq</X509Certificate></X509Data></KeyInfo></Signature></NFe><protNFe xmlns=http://www.portalfiscal.inf.br/nfe versao=3.10><infProt Id=NFe342170020756388><tpAmb>1</tpAmb><verAplic>SVRS201702151618</verAplic><chNFe>42170285789782000142550050003807161000479510</chNFe><dhRecbto>2017-02-20T09:36:59-03:00</dhRecbto><nProt>342170020756388</nProt><digVal>LKLyf3lrObBwD3rfm3nm9lUvp7A=</digVal><cStat>100</cStat><xMotivo>Autorizado o uso da NF-e</xMotivo></infProt></protNFe></nfeProc>', -- varchar(max)
    --    @Ds_Arquivo = 'C:\Temp\Teste.xml' -- varchar(1501)
*/

-- ============================================================
-- DEFINIÇÃO — Management.[sp_Escreve_Arquivo_FSO]
-- ============================================================

-- Recebe uma string e o caminho destino; escreve o arquivo via FileSystemObject
CREATE OR ALTER PROCEDURE Management.[sp_Escreve_Arquivo_FSO] (
     @String     VARCHAR(MAX)
    ,@Ds_Arquivo VARCHAR(1501)
)
AS
BEGIN

    -- Declaração das variáveis de controle OLE e status de operação
    DECLARE
         @objFileSystem   INT
        ,@objTextStream   INT
        ,@objErrorObject  INT
        ,@strErrorMessage VARCHAR(1000)
        ,@Command         VARCHAR(1000)
        ,@hr              INT;

    SET NOCOUNT ON;

    -- Inicializa a mensagem de erro padrão antes de criar o objeto
    SELECT @strErrorMessage = 'opening the File System Object';
    
    -- Cria o objeto FileSystemObject via OLE Automation
    EXECUTE @hr = sp_OACreate
        'Scripting.FileSystemObject',
        @objFileSystem OUT;

    
    -- Registra contexto de erro antes da criação do arquivo
    IF @hr = 0
    BEGIN
        SELECT
             @objErrorObject  = @objFileSystem
            ,@strErrorMessage = 'Creating file ' + @Ds_Arquivo + '';
    END;
    
    
    -- Cria o arquivo texto no disco (overwrite = 2, unicode = True)
    IF @hr = 0
    BEGIN
        EXECUTE @hr = sp_OAMethod
            @objFileSystem,
            'CreateTextFile',
            @objTextStream OUT,
            @Ds_Arquivo,
            2,
            True;
    END;

    -- Registra contexto de erro antes de gravar o conteúdo
    IF @hr = 0
    BEGIN
        SELECT
             @objErrorObject  = @objTextStream
            ,@strErrorMessage = 'writing to the file ' + @Ds_Arquivo + '';
    END;
    
    
    -- Escreve a string no arquivo aberto
    IF @hr = 0
    BEGIN
        EXECUTE @hr = sp_OAMethod
            @objTextStream,
            'Write',
            NULL,
            @String;
    END;

    
    -- Registra contexto de erro antes de fechar o arquivo
    IF @hr = 0
    BEGIN
        SELECT
             @objErrorObject  = @objTextStream
            ,@strErrorMessage = 'closing the file ' + @Ds_Arquivo + '';
    END;
    
    
    -- Fecha o stream após a escrita
    IF @hr = 0
    BEGIN
        EXECUTE @hr = sp_OAMethod
            @objTextStream,
            'Close';
    END;

    
    -- Tratamento de erro: captura detalhes OLE e lança exceção
    IF @hr <> 0
    BEGIN
    
        DECLARE
             @Source      VARCHAR(255)
            ,@Description VARCHAR(255)
            ,@Helpfile    VARCHAR(255)
            ,@HelpID      INT;
    
        -- Obtém informações detalhadas do erro a partir do objeto com falha
        EXECUTE sp_OAGetErrorInfo
            @objErrorObject,
            @source      OUTPUT,
            @Description OUTPUT,
            @Helpfile    OUTPUT,
            @HelpID      OUTPUT;
        
        
        -- Compõe a mensagem de erro com contexto e descrição OLE
        SELECT @strErrorMessage =
            'Error whilst ' + COALESCE(@strErrorMessage, 'doing something')
            + ', ' + COALESCE(@Description, '');
        
        
        RAISERROR (@strErrorMessage, 16, 1);
        
    END
    
    
    -- Libera os objetos OLE da memória após a escrita
    EXECUTE sp_OADestroy @objTextStream;
    EXECUTE sp_OADestroy @objFileSystem;

END
GO
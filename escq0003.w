&ANALYZE-SUSPEND _VERSION-NUMBER AB_v10r12 GUI ADM2
&ANALYZE-RESUME
/* Connected Databases 
*/
&Scoped-define WINDOW-NAME wWin
{adecomm/appserv.i}
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _DEFINITIONS wWin 
/*------------------------------------------------------------------------

  File: 

  Description: from cntnrwin.w - ADM SmartWindow Template

  Input Parameters:
      <none>

  Output Parameters:
      <none>

  History: New V9 Version - January 15, 1998
          
------------------------------------------------------------------------*/
/*          This .W file was created with the Progress AB.              */
/*----------------------------------------------------------------------*/

/* Create an unnamed pool to store all the widgets created 
     by this procedure. This is a good default which assures
     that this procedure's triggers and internal procedures 
     will execute in this procedure's storage, and that proper
     cleanup will occur on deletion of the procedure. */

CREATE WIDGET-POOL.

/* ***************************  Definitions  ************************** */

 
 DEFINE TEMP-TABLE tt-req-ord NO-UNDO
    FIELD it-codigo       AS CHARACTER
    FIELD un              AS CHARACTER
    FIELD desc-item       AS CHARACTER
    FIELD lote            AS CHARACTER
    FIELD valid-lote      AS DATE
    FIELD qt-requisitada  AS DECIMAL
    FIELD qt-embalagens   AS DECIMAL
    FIELD capacidade      AS DECIMAL
    FIELD qt-receita      AS DECIMAL
    FIELD qt-pesar        AS DECIMAL
    FIELD situacao        AS CHARACTER
    .
 
 DEFINE TEMP-TABLE tt-pesagem-item NO-UNDO
    FIELD imprimir  AS LOGICAL    // [ ]
    FIELD tipo      AS CHARACTER  // EMBALAGEM / VOLUME
    FIELD it-codigo AS CHARACTER  // 12345
    FIELD lote      AS CHARACTER  // XPTOABCD
    FIELD desc-item AS CHARACTER  // Uva passa
    FIELD un        AS CHARACTER  // KG
    FIELD qt-pesar  AS DECIMAL    // 20
    FIELD qt-volume AS INTEGER    // 1
    FIELD qt-pesado AS DECIMAL    // 20,1
    FIELD situacao  AS CHARACTER  // OK
    . 
    


/* Parameters Definitions ---                                           */

/* Local Variable Definitions ---                                       */

/* Item atualmente selecionado */
DEFINE VARIABLE dPesoMaxVolume     AS DECIMAL      NO-UNDO INITIAL 48. /* CONSTANTE */
DEFINE VARIABLE dPesoMaxBalanca    AS DECIMAL      NO-UNDO INITIAL 49. /* CONSTANTE */
DEFINE VARIABLE cDescItem          AS CHARACTER NO-UNDO.
DEFINE VARIABLE cItCodigo          AS CHARACTER NO-UNDO.
DEFINE VARIABLE iSeqPesar          AS INTEGER   NO-UNDO.
DEFINE VARIABLE dToleranciaPesagem AS DECIMAL   NO-UNDO INITIAL 2. /* CONSTANTE */
DEFINE VARIABLE dPesoMinBalanca    AS DECIMAL   NO-UNDO INITIAL 0.005. /* CONSTANTE - 5 g */
DEFINE VARIABLE cOrdemProducao     AS CHARACTER NO-UNDO.
DEFINE VARIABLE iLarguraEtiqueta   AS INTEGER NO-UNDO INITIAL 40. /* CONSTANTE - colunas */
/* A fonte da impressora eh proporcional: o hifen eh cerca de 1,73x mais
   estreito que o "=", entao 40 hifens param bem antes da regua dupla.
   69 faz a regua simples terminar na mesma coluna. Medido na saida PDF. */
DEFINE VARIABLE iLarguraSepSimp    AS INTEGER NO-UNDO INITIAL 69. /* CONSTANTE - hifens */
//DEFINE VARIABLE iAlturaEtiqueta  AS INTEGER NO-UNDO INITIAL 20. /* CONSTANTE - linhas  */
DEFINE VARIABLE cNomeBalanca       AS CHARACTER NO-UNDO INITIAL "Prix TI 400".


{src/adm2/widgetprto.i}.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-PREPROCESSOR-BLOCK 

/* ********************  Preprocessor Definitions  ******************** */

&Scoped-define PROCEDURE-TYPE SmartWindow
&Scoped-define DB-AWARE no

&Scoped-define ADM-CONTAINER WINDOW

&Scoped-define ADM-SUPPORTED-LINKS Data-Target,Data-Source,Page-Target,Update-Source,Update-Target,Filter-target,Filter-Source

/* Name of designated FRAME-NAME and/or first browse and/or first query */
&Scoped-define FRAME-NAME fMain
&Scoped-define BROWSE-NAME br-itensReq

/* Internal Tables (found by Frame, Query & Browse Queries)             */
&Scoped-define INTERNAL-TABLES tt-req-ord tt-pesagem-item

/* Definitions for BROWSE br-itensReq                                   */
&Scoped-define FIELDS-IN-QUERY-br-itensReq // tt-item.sel tt-req-ord.it-codigo tt-req-ord.un tt-req-ord.desc-item tt-req-ord.lote tt-req-ord.valid-lote tt-req-ord.qt-requisitada tt-req-ord.qt-embalagens tt-req-ord.qt-pesar tt-req-ord.situacao   
&Scoped-define ENABLED-FIELDS-IN-QUERY-br-itensReq   
&Scoped-define SELF-NAME br-itensReq
&Scoped-define QUERY-STRING-br-itensReq FOR EACH tt-req-ord
&Scoped-define OPEN-QUERY-br-itensReq OPEN QUERY {&SELF-NAME}     FOR EACH tt-req-ord     .
&Scoped-define TABLES-IN-QUERY-br-itensReq tt-req-ord
&Scoped-define FIRST-TABLE-IN-QUERY-br-itensReq tt-req-ord


/* Definitions for BROWSE brPesagem                                     */
&Scoped-define FIELDS-IN-QUERY-brPesagem tt-pesagem-item.imprimir tt-pesagem-item.it-codigo tt-pesagem-item.desc-item tt-pesagem-item.un tt-pesagem-item.tipo tt-pesagem-item.qt-pesar tt-pesagem-item.qt-volume tt-pesagem-item.qt-pesado tt-pesagem-item.situacao   
&Scoped-define ENABLED-FIELDS-IN-QUERY-brPesagem tt-pesagem-item.imprimir   
&Scoped-define ENABLED-TABLES-IN-QUERY-brPesagem tt-pesagem-item
&Scoped-define FIRST-ENABLED-TABLE-IN-QUERY-brPesagem tt-pesagem-item
&Scoped-define SELF-NAME brPesagem
&Scoped-define QUERY-STRING-brPesagem FOR EACH tt-pesagem-item
&Scoped-define OPEN-QUERY-brPesagem OPEN QUERY {&SELF-NAME} FOR EACH tt-pesagem-item.
&Scoped-define TABLES-IN-QUERY-brPesagem tt-pesagem-item
&Scoped-define FIRST-TABLE-IN-QUERY-brPesagem tt-pesagem-item


/* Definitions for FRAME fMain                                          */
&Scoped-define OPEN-BROWSERS-IN-QUERY-fMain ~
    ~{&OPEN-QUERY-br-itensReq}~
    ~{&OPEN-QUERY-brPesagem}

/* Standard List Definitions                                            */
&Scoped-Define ENABLED-OBJECTS fi-ordem bt-buscarOrdem brPesagem btMarcar ~
btTodos 
&Scoped-Define DISPLAYED-OBJECTS fi-ordem fi-num-item fi-Item fi-qtdOrdem-2 ~
fi-situacao fi-aviso-pesagem fi-peso-item 

/* Custom List Definitions                                              */
/* List-1,List-2,List-3,List-4,List-5,List-6                            */

/* _UIB-PREPROCESSOR-BLOCK-END */
&ANALYZE-RESUME



/* ***********************  Control Definitions  ********************** */

/* Define the widget handle for the window                              */
DEFINE VAR wWin AS WIDGET-HANDLE NO-UNDO.

/* Definitions of handles for SmartObjects                              */
DEFINE VARIABLE h_folder AS HANDLE NO-UNDO.

/* Definitions of the field level widgets                               */
DEFINE BUTTON bt-buscarOrdem 
     LABEL "Buscar" 
     SIZE 15 BY 1.

DEFINE BUTTON bt-pesagem 
     LABEL "Iniciar Pesagem" 
     SIZE 22 BY 1.

DEFINE BUTTON btConfirmarPeso 
     LABEL "Confirmar" 
     SIZE 15 BY 1.13.

DEFINE BUTTON btImprimir 
     LABEL "Imprimir" 
     SIZE 15 BY 1.13.

DEFINE BUTTON btMarcar 
     LABEL "Marcar / Desmarcar" 
     SIZE 20 BY 1.13.

DEFINE BUTTON btTodos 
     LABEL "Todos / Nenhum" 
     SIZE 20 BY 1.13.

DEFINE VARIABLE fi-aviso-pesagem AS CHARACTER FORMAT "X(256)":U 
     LABEL "Item a ser pesado" 
     VIEW-AS FILL-IN 
     SIZE 50 BY 1 NO-UNDO.

DEFINE VARIABLE fi-Item AS CHARACTER FORMAT "X(256)":U 
     VIEW-AS FILL-IN 
     SIZE 55 BY 1 NO-UNDO.

DEFINE VARIABLE fi-num-item AS CHARACTER FORMAT "X(256)":U 
     LABEL "Item Ordem" 
     VIEW-AS FILL-IN 
     SIZE 15 BY 1 NO-UNDO.

DEFINE VARIABLE fi-ordem AS CHARACTER FORMAT "X(256)":U 
     LABEL "Ordem de Produ‡Æo" 
     VIEW-AS FILL-IN 
     SIZE 16 BY 1 NO-UNDO.

DEFINE VARIABLE fi-peso-item AS DECIMAL FORMAT "->>,>>9.99":U INITIAL 0 
     LABEL "Peso" 
     VIEW-AS FILL-IN 
     SIZE 30 BY 1 NO-UNDO.

DEFINE VARIABLE fi-qtdOrdem-2 AS CHARACTER FORMAT "X(256)":U 
     LABEL "Quantidade Ordem" 
     VIEW-AS FILL-IN 
     SIZE 15 BY 1 NO-UNDO.

DEFINE VARIABLE fi-situacao AS CHARACTER FORMAT "X(256)":U 
     LABEL "Situa‡Æo Pesagem" 
     VIEW-AS FILL-IN 
     SIZE 15 BY 1 NO-UNDO.

/* Query definitions                                                    */
&ANALYZE-SUSPEND
DEFINE QUERY br-itensReq FOR 
      tt-req-ord SCROLLING.

DEFINE QUERY brPesagem FOR 
      tt-pesagem-item SCROLLING.
&ANALYZE-RESUME

/* Browse definitions                                                   */
DEFINE BROWSE br-itensReq
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _DISPLAY-FIELDS br-itensReq wWin _FREEFORM
  QUERY br-itensReq DISPLAY
      // tt-item.sel   COLUMN-LABEL "Sel" VIEW-AS TOGGLE-BOX
tt-req-ord.it-codigo      FORMAT "x(16)"         LABEL "Item"                     WIDTH 15
tt-req-ord.un             FORMAT "x(5)"          LABEL "Un"                       WIDTH 5
tt-req-ord.desc-item      FORMAT "x(40)"         LABEL "Descri‡Æo"                WIDTH 35
tt-req-ord.lote           FORMAT "x(20)"         LABEL "Lote"                     WIDTH 20
tt-req-ord.valid-lote     FORMAT "99/99/9999"    LABEL "Validade Lote"            WIDTH 10
tt-req-ord.qt-requisitada FORMAT ">>,>>9.9999"   LABEL "Qtd. Requisitada"         WIDTH 12
tt-req-ord.qt-embalagens  FORMAT ">>,>>9.9999"   LABEL "Qtd. Embalagens Fechadas" WIDTH 12
tt-req-ord.qt-pesar       FORMAT ">>,>>9.9999"   LABEL "Qtd. Pesar"               WIDTH 12
tt-req-ord.situacao       FORMAT "x(20)"         LABEL "Pesado?"                  WIDTH 12
/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME
    WITH NO-ROW-MARKERS SEPARATORS SIZE 140 BY 5.75 FIT-LAST-COLUMN.

DEFINE BROWSE brPesagem
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _DISPLAY-FIELDS brPesagem wWin _FREEFORM
  QUERY brPesagem DISPLAY
      tt-pesagem-item.imprimir
    COLUMN-LABEL "Sel"
    VIEW-AS TOGGLE-BOX

tt-pesagem-item.it-codigo
    FORMAT "x(15)"
    COLUMN-LABEL "Item"
    WIDTH 15

tt-pesagem-item.desc-item
    FORMAT "x(35)"
    COLUMN-LABEL "Descri‡Æo"
    WIDTH 35

tt-pesagem-item.un
    FORMAT "x(5)"
    COLUMN-LABEL "Un"
    WIDTH 5
    
tt-pesagem-item.tipo
    FORMAT "x(12)"
    COLUMN-LABEL "Tipo"
    WIDTH 13

tt-pesagem-item.qt-pesar
    FORMAT "->>>,>>9.9999"
    COLUMN-LABEL "Qtd. Pesar"
    WIDTH 15

tt-pesagem-item.qt-volume
    FORMAT "->>>,>>9"
    COLUMN-LABEL "Volume"
    WIDTH 10

tt-pesagem-item.qt-pesado
    FORMAT "->>>,>>9.9999"
    COLUMN-LABEL "Qtd. Pesada"
    WIDTH 15

tt-pesagem-item.situacao
    FORMAT "x(15)"
    COLUMN-LABEL "Situa‡Æo"
    WIDTH 15
   
   
ENABLE
    tt-pesagem-item.imprimir
/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME
    WITH NO-ROW-MARKERS SEPARATORS SIZE 140 BY 5.75 FIT-LAST-COLUMN.


/* ************************  Frame Definitions  *********************** */

DEFINE FRAME fMain
     fi-ordem AT ROW 2.75 COL 23 COLON-ALIGNED WIDGET-ID 2
     bt-buscarOrdem AT ROW 2.75 COL 43 WIDGET-ID 4
     fi-num-item AT ROW 4.5 COL 23.14 COLON-ALIGNED WIDGET-ID 18
     fi-Item AT ROW 4.5 COL 39.57 COLON-ALIGNED NO-LABEL WIDGET-ID 6
     fi-qtdOrdem-2 AT ROW 6 COL 23.14 COLON-ALIGNED WIDGET-ID 16
     fi-situacao AT ROW 7.5 COL 23 COLON-ALIGNED WIDGET-ID 10
     br-itensReq AT ROW 12.5 COL 3 WIDGET-ID 200
     bt-pesagem AT ROW 18.5 COL 3 WIDGET-ID 14
     fi-aviso-pesagem AT ROW 20.29 COL 19 COLON-ALIGNED WIDGET-ID 20
     btConfirmarPeso AT ROW 21.83 COL 41.29 WIDGET-ID 24
     fi-peso-item AT ROW 21.92 COL 7.29 COLON-ALIGNED WIDGET-ID 22
     brPesagem AT ROW 23.79 COL 2.86 WIDGET-ID 300
     btMarcar AT ROW 29.75 COL 3 WIDGET-ID 34
     btTodos AT ROW 29.75 COL 24 WIDGET-ID 36
     btImprimir AT ROW 29.75 COL 128 WIDGET-ID 30
     "Itens Requisitados Para Ordem" VIEW-AS TEXT
          SIZE 35 BY .67 AT ROW 11.75 COL 3 WIDGET-ID 12
    WITH 1 DOWN NO-BOX KEEP-TAB-ORDER OVERLAY 
         SIDE-LABELS NO-UNDERLINE THREE-D 
         AT COL 1 ROW 1
         SIZE 144 BY 30.38 WIDGET-ID 100.


/* *********************** Procedure Settings ************************ */

&ANALYZE-SUSPEND _PROCEDURE-SETTINGS
/* Settings for THIS-PROCEDURE
   Type: SmartWindow
   Allow: Basic,Browse,DB-Fields,Query,Smart,Window
   Container Links: Data-Target,Data-Source,Page-Target,Update-Source,Update-Target,Filter-target,Filter-Source
   Other Settings: APPSERVER
 */
&ANALYZE-RESUME _END-PROCEDURE-SETTINGS

/* *************************  Create Window  ************************** */

&ANALYZE-SUSPEND _CREATE-WINDOW
IF SESSION:DISPLAY-TYPE = "GUI":U THEN
  CREATE WINDOW wWin ASSIGN
         HIDDEN             = YES
         TITLE              = "Pesagem Ordem Produ‡Æo"
         HEIGHT             = 30.54
         WIDTH              = 145
         MAX-HEIGHT         = 33.38
         MAX-WIDTH          = 219.43
         VIRTUAL-HEIGHT     = 33.38
         VIRTUAL-WIDTH      = 219.43
         RESIZE             = no
         SCROLL-BARS        = no
         STATUS-AREA        = no
         BGCOLOR            = ?
         FGCOLOR            = ?
         THREE-D            = yes
         MESSAGE-AREA       = no
         SENSITIVE          = yes.
ELSE {&WINDOW-NAME} = CURRENT-WINDOW.
/* END WINDOW DEFINITION                                                */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _INCLUDED-LIB wWin 
/* ************************* Included-Libraries *********************** */

{src/adm2/containr.i}

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME




/* ***********  Runtime Attributes and AppBuilder Settings  *********** */

&ANALYZE-SUSPEND _RUN-TIME-ATTRIBUTES
/* SETTINGS FOR WINDOW wWin
  VISIBLE,,RUN-PERSISTENT                                               */
/* SETTINGS FOR FRAME fMain
   FRAME-NAME                                                           */
/* BROWSE-TAB br-itensReq fi-situacao fMain */
/* BROWSE-TAB brPesagem fi-peso-item fMain */
/* SETTINGS FOR BROWSE br-itensReq IN FRAME fMain
   NO-ENABLE                                                            */
/* SETTINGS FOR BUTTON bt-pesagem IN FRAME fMain
   NO-ENABLE                                                            */
/* SETTINGS FOR BUTTON btConfirmarPeso IN FRAME fMain
   NO-ENABLE                                                            */
/* SETTINGS FOR BUTTON btImprimir IN FRAME fMain
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-aviso-pesagem IN FRAME fMain
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-Item IN FRAME fMain
   NO-ENABLE                                                            */
ASSIGN 
       fi-Item:READ-ONLY IN FRAME fMain        = TRUE.

/* SETTINGS FOR FILL-IN fi-num-item IN FRAME fMain
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-peso-item IN FRAME fMain
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-qtdOrdem-2 IN FRAME fMain
   NO-ENABLE                                                            */
ASSIGN 
       fi-qtdOrdem-2:READ-ONLY IN FRAME fMain        = TRUE.

/* SETTINGS FOR FILL-IN fi-situacao IN FRAME fMain
   NO-ENABLE                                                            */
ASSIGN 
       fi-situacao:READ-ONLY IN FRAME fMain        = TRUE.

IF SESSION:DISPLAY-TYPE = "GUI":U AND VALID-HANDLE(wWin)
THEN wWin:HIDDEN = yes.

/* _RUN-TIME-ATTRIBUTES-END */
&ANALYZE-RESUME


/* Setting information for Queries and Browse Widgets fields            */

&ANALYZE-SUSPEND _QUERY-BLOCK BROWSE br-itensReq
/* Query rebuild information for BROWSE br-itensReq
     _START_FREEFORM
OPEN QUERY {&SELF-NAME}
    FOR EACH tt-req-ord
    .
     _END_FREEFORM
     _Query            is OPENED
*/  /* BROWSE br-itensReq */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _QUERY-BLOCK BROWSE brPesagem
/* Query rebuild information for BROWSE brPesagem
     _START_FREEFORM
OPEN QUERY {&SELF-NAME} FOR EACH tt-pesagem-item
     _END_FREEFORM
     _Query            is OPENED
*/  /* BROWSE brPesagem */
&ANALYZE-RESUME

 



/* ************************  Control Triggers  ************************ */

&Scoped-define SELF-NAME wWin
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL wWin wWin
ON END-ERROR OF wWin /* Pesagem Ordem Produ‡Æo */
OR ENDKEY OF {&WINDOW-NAME} ANYWHERE DO:
  /* This case occurs when the user presses the "Esc" key.
     In a persistently run window, just ignore this.  If we did not, the
     application would exit. */
  IF THIS-PROCEDURE:PERSISTENT THEN RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL wWin wWin
ON WINDOW-CLOSE OF wWin /* Pesagem Ordem Produ‡Æo */
DO:
  /* This ADM code must be left here in order for the SmartWindow
     and its descendents to terminate properly on exit. */
  APPLY "CLOSE":U TO THIS-PROCEDURE.
  RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define BROWSE-NAME br-itensReq
&Scoped-define SELF-NAME br-itensReq
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL br-itensReq wWin
ON VALUE-CHANGED OF br-itensReq IN FRAME fMain
DO:
    /* Exibe ITEM a ser pesado */
    IF AVAILABLE tt-req-ord THEN DO:
        FIND FIRST ITEM NO-LOCK
            WHERE ITEM.it-codigo = tt-req-ord.it-codigo
            NO-ERROR.
        IF AVAILABLE ITEM THEN DO:
            ASSIGN
                fi-aviso-pesagem:SCREEN-VALUE IN FRAME fMain =
                CAPS(ITEM.desc-item).
        END.
        ELSE DO:
            ASSIGN
                fi-aviso-pesagem:SCREEN-VALUE IN FRAME fMain =
                "".
        END.
    END.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-buscarOrdem
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-buscarOrdem wWin
ON CHOOSE OF bt-buscarOrdem IN FRAME fMain /* Buscar */
DO:
    RUN pi-buscar-op.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-pesagem
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-pesagem wWin
ON CHOOSE OF bt-pesagem IN FRAME fMain /* Iniciar Pesagem */
DO:
    RUN pi-iniciar-pesagem.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME btConfirmarPeso
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL btConfirmarPeso wWin
ON CHOOSE OF btConfirmarPeso IN FRAME fMain /* Confirmar */
DO:
    RUN pi-confirmar-pesagem.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME btImprimir
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL btImprimir wWin
ON CHOOSE OF btImprimir IN FRAME fMain /* Imprimir */
DO:
    IF AVAILABLE tt-pesagem-item THEN
        ASSIGN BROWSE brPesagem tt-pesagem-item.imprimir NO-ERROR.
    RUN pi-imprimir-etiquetas.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME btMarcar
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL btMarcar wWin
ON CHOOSE OF btMarcar IN FRAME fMain /* Marcar / Desmarcar */
DO:

    /*=============================================================
        LOCALIZA O REGISTRO ATUAL DO BROWSE
    ===============================================================*/

    FIND CURRENT tt-pesagem-item NO-ERROR.

    /*=============================================================
        MARCA OU DESMARCA O CHECKBOX DO ITEM
    ===============================================================*/

    IF AVAILABLE tt-pesagem-item THEN DO:

        ASSIGN
            tt-pesagem-item.imprimir =
                NOT tt-pesagem-item.imprimir.

        DISPLAY
            tt-pesagem-item.imprimir
            WITH BROWSE brPesagem.

    END.

    /*=============================================================
        ATUALIZA O ESTADO DO BOTAO DE IMPRIMIR
    ===============================================================*/

    RUN pi-habilita-btImprimir.

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME btTodos
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL btTodos wWin
ON CHOOSE OF btTodos IN FRAME fMain /* Todos / Nenhum */
DO:
    DEFINE VARIABLE l-marcar AS LOGICAL NO-UNDO.

    DEFINE BUFFER bf-vol FOR tt-pesagem-item.
    
    /*=============================================================
        VERIFICA SE EXISTEM REGISTROS NO BROWSE
    ===============================================================*/ 
    
    IF NOT CAN-FIND (FIRST bf-vol) THEN
        RETURN.
    
    /*=============================================================
        DEFINE SE VAI MARCAR OU DESMARCAR TODOS
        Se existir algum registro desmarcado, marca todos.
        Caso contrario, desmarca todos.
    ===============================================================*/
    ASSIGN
        l-marcar = CAN-FIND(FIRST bf-vol WHERE bf-vol.imprimir = NO).

    /*=============================================================
        MARCA OU DESMARCA TODOS OS REGISTROS
    ===============================================================*/

    FOR EACH bf-vol:
        ASSIGN
            bf-vol.imprimir = l-marcar.
    END.

    /*=============================================================
        ATUALIZA O BROWSE
    ===============================================================*/

    brPesagem:REFRESH().

    /*=============================================================
        ATUALIZA O ESTADO DO BOTAO DE IMPRIMIR
    ===============================================================*/

    RUN pi-habilita-btImprimir.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME fi-ordem
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-ordem wWin
ON RETURN OF fi-ordem IN FRAME fMain /* Ordem de Produ‡Æo */
DO:
  RUN pi-buscar-op.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&UNDEFINE SELF-NAME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _MAIN-BLOCK wWin 


/* ***************************  Main Block  *************************** */

/* Include custom  Main Block code for SmartWindows. */
{src/adm2/windowmn.i}


/* Escuta clique no checkbox do browse brPesagem --> habilitar/desabilitar btImprimir */
ON VALUE-CHANGED OF tt-pesagem-item.imprimir IN BROWSE brPesagem DO:
    ASSIGN BROWSE brPesagem tt-pesagem-item.imprimir.
    RUN pi-habilita-btImprimir.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


/* **********************  Internal Procedures  *********************** */

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE adm-create-objects wWin  _ADM-CREATE-OBJECTS
PROCEDURE adm-create-objects :
/*------------------------------------------------------------------------------
  Purpose:     Create handles for all SmartObjects used in this procedure.
               After SmartObjects are initialized, then SmartLinks are added.
  Parameters:  <none>
------------------------------------------------------------------------------*/
  DEFINE VARIABLE currentPage  AS INTEGER NO-UNDO.

  ASSIGN currentPage = getCurrentPage().

  CASE currentPage: 

    WHEN 0 THEN DO:
       RUN constructObject (
             INPUT  'adm2/folder.w':U ,
             INPUT  FRAME fMain:HANDLE ,
             INPUT  'FolderLabels':U + 'Busca Ordem Produ‡Æo' + 'FolderTabWidth0FolderFont-1HideOnInitnoDisableOnInitnoObjectLayout':U ,
             OUTPUT h_folder ).
       RUN repositionObject IN h_folder ( 1.00 , 2.00 ) NO-ERROR.
       RUN resizeObject IN h_folder ( 30.00 , 142.00 ) NO-ERROR.

       /* Links to SmartFolder h_folder. */
       RUN addLink ( h_folder , 'Page':U , THIS-PROCEDURE ).

       /* Adjust the tab order of the smart objects. */
       RUN adjustTabOrder ( h_folder ,
             fi-ordem:HANDLE IN FRAME fMain , 'BEFORE':U ).
    END. /* Page 0 */

  END CASE.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE disable_UI wWin  _DEFAULT-DISABLE
PROCEDURE disable_UI :
/*------------------------------------------------------------------------------
  Purpose:     DISABLE the User Interface
  Parameters:  <none>
  Notes:       Here we clean-up the user-interface by deleting
               dynamic widgets we have created and/or hide 
               frames.  This procedure is usually called when
               we are ready to "clean-up" after running.
------------------------------------------------------------------------------*/
  /* Delete the WINDOW we created */
  IF SESSION:DISPLAY-TYPE = "GUI":U AND VALID-HANDLE(wWin)
  THEN DELETE WIDGET wWin.
  IF THIS-PROCEDURE:PERSISTENT THEN DELETE PROCEDURE THIS-PROCEDURE.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE enable_UI wWin  _DEFAULT-ENABLE
PROCEDURE enable_UI :
/*------------------------------------------------------------------------------
  Purpose:     ENABLE the User Interface
  Parameters:  <none>
  Notes:       Here we display/view/enable the widgets in the
               user-interface.  In addition, OPEN all queries
               associated with each FRAME and BROWSE.
               These statements here are based on the "Other 
               Settings" section of the widget Property Sheets.
------------------------------------------------------------------------------*/
  DISPLAY fi-ordem fi-num-item fi-Item fi-qtdOrdem-2 fi-situacao 
          fi-aviso-pesagem fi-peso-item 
      WITH FRAME fMain IN WINDOW wWin.
  ENABLE fi-ordem bt-buscarOrdem brPesagem btMarcar btTodos 
      WITH FRAME fMain IN WINDOW wWin.
  {&OPEN-BROWSERS-IN-QUERY-fMain}
  VIEW wWin.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE exitObject wWin 
PROCEDURE exitObject :
/*------------------------------------------------------------------------------
  Purpose:  Window-specific override of this procedure which destroys 
            its contents and itself.
    Notes:  
------------------------------------------------------------------------------*/

  APPLY "CLOSE":U TO THIS-PROCEDURE.
  RETURN.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-aplica-logs-pesagem wWin 
PROCEDURE pi-aplica-logs-pesagem :
/*------------------------------------------------------------------------------
  PROCEDURE pi-aplica-logs-pesagem
  Purpose:     Sobrepoe o historico ao plano: todo volume que ja tem pesagem
               aprovada em es_pesagem_log vira CONCLUIDO, com o peso real.
  Parameters:  piOrdem (INPUT) - numero da ordem de producao
  Notes:       Rodar depois de pi-monta-plano-pesagem.
               Casa por item + lote + numero do volume: o mesmo item pode vir
               em dois lotes na mesma OP.
               Volume repesado: vale a ultima tentativa aprovada.
               HISTORICO MANDA onde existe - o alvo tambem vem do log
               (peso + qt_desvio), e nao do plano. O plano eh recalculado a
               cada busca e a capacidade_embalagem da escq0004 pode ter mudado
               depois da pesagem; o que ficou gravado eh o que valeu.
               Log sem linha correspondente no plano de hoje vira linha nova,
               no fim do browse: o que foi pesado nunca some da tela.
------------------------------------------------------------------------------*/
    DEFINE INPUT PARAMETER piOrdem AS INTEGER NO-UNDO.

    DEFINE VARIABLE cConcluido AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cDescItem  AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cUn        AS CHARACTER NO-UNDO.

    DEFINE BUFFER bf-log FOR es_pesagem_log.
    DEFINE BUFFER bf-vol FOR tt-pesagem-item.
    DEFINE BUFFER bf-tt  FOR tt-req-ord.

    RUN pi-verificar-situacao (INPUT 3, OUTPUT cConcluido).

    FOR EACH bf-log NO-LOCK
        WHERE bf-log.nr_ordem  = piOrdem
          AND bf-log.resultado = 1
        BREAK BY bf-log.item
              BY bf-log.lote
              BY bf-log.volume
              BY bf-log.tentativa:

        /* volume repesado: so a ultima tentativa aprovada vale */
        IF NOT LAST-OF(bf-log.volume) THEN
            NEXT.

        FIND FIRST bf-vol
            WHERE bf-vol.it-codigo = bf-log.item
              AND bf-vol.lote      = bf-log.lote
              AND bf-vol.tipo      = "PESAGEM"
              AND bf-vol.qt-volume = bf-log.volume
            NO-ERROR.

        /* pesado, mas o plano de hoje nao previu esta linha: cria no fim */
        IF NOT AVAILABLE bf-vol THEN DO:

            FIND FIRST bf-tt NO-LOCK
                WHERE bf-tt.it-codigo = bf-log.item
                  AND bf-tt.lote      = bf-log.lote
                NO-ERROR.

            ASSIGN
                cDescItem = (IF AVAILABLE bf-tt THEN bf-tt.desc-item ELSE "")
                cUn       = (IF AVAILABLE bf-tt THEN bf-tt.un        ELSE "").

            RUN pi-cria-linha-pesagem (INPUT "PESAGEM",
                                       INPUT bf-log.item,
                                       INPUT bf-log.lote,
                                       INPUT cDescItem,
                                       INPUT cUn,
                                       INPUT bf-log.volume,
                                       INPUT bf-log.peso + bf-log.qt_desvio,
                                       INPUT cConcluido).

            /* a linha recem criada segue corrente no buffer default da tt */
            ASSIGN tt-pesagem-item.qt-pesado = bf-log.peso.
            NEXT.
        END.

        ASSIGN
            bf-vol.qt-pesar  = bf-log.peso + bf-log.qt_desvio
            bf-vol.qt-pesado = bf-log.peso
            bf-vol.situacao  = cConcluido.
    END.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-avisa-embalagens wWin 
PROCEDURE pi-avisa-embalagens :
/*------------------------------------------------------------------------------
  PROCEDURE pi-avisa-embalagens
  Purpose:     Avisa o operador, num unico alert-box, o que ele tem de separar
               a mao antes de comecar: as embalagens e os componentes abaixo do
               minimo da balanca.
  Parameters:  <none>
  Notes:       Uma mensagem so para a OP inteira - nao uma por componente.
               Peso sempre em KG.
               Rodar depois de pi-carrega-brPesagem.
------------------------------------------------------------------------------*/
    DEFINE VARIABLE cEmbalagens AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cMinimos    AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cAviso      AS CHARACTER NO-UNDO.

    DEFINE BUFFER bf-tt FOR tt-req-ord.

    FOR EACH bf-tt NO-LOCK:

        IF bf-tt.qt-embalagens > 0 THEN
            ASSIGN cEmbalagens = cEmbalagens + CHR(10)
                   + "   " + TRIM(bf-tt.it-codigo)
                   + " (lote " + TRIM(bf-tt.lote) + "):  "
                   + TRIM(STRING(bf-tt.qt-embalagens, "->>>,>>9"))
                   + " embalagens de "
                   + TRIM(STRING(bf-tt.capacidade, "->>>,>>9.9999")) + " KG".

        IF bf-tt.qt-pesar > 0 AND bf-tt.qt-pesar < dPesoMinBalanca THEN
            ASSIGN cMinimos = cMinimos + CHR(10)
                   + "   " + TRIM(bf-tt.it-codigo)
                   + " (lote " + TRIM(bf-tt.lote) + "):  "
                   + TRIM(STRING(bf-tt.qt-pesar, "->>>,>>9.9999")) + " KG".
    END.

    IF cEmbalagens <> "" THEN
        ASSIGN cAviso = "Separe as embalagens antes de iniciar a pesagem:"
                      + CHR(10) + cEmbalagens + CHR(10).

    IF cMinimos <> "" THEN
        ASSIGN cAviso = cAviso + CHR(10)
                      + "Abaixo do minimo da balanca ("
                      + TRIM(STRING(dPesoMinBalanca, ">>9.999")) + " KG)."
                      + " Separe a mao, sem pesar:"
                      + CHR(10) + cMinimos.

    IF cAviso = "" THEN
        RETURN.

    MESSAGE cAviso
        VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-buscar-op wWin 
PROCEDURE pi-buscar-op :
/*------------------------------------------------------------------------------
  pi-buscar-op --> executada quando clica em [BUSCAR]
  Purpose:     Processa a OP informada, validando a ordem e preparando os dados
               necess rios para a tela de pesagem.

               Executa a cria‡Æo dos registros de mistura e componentes, carrega
               o cabe‡alho, monta os itens da OP e atualiza o browse de pesagem
               e os botäes da tela.

  Parameters:  <none>
------------------------------------------------------------------------------*/
    DEFINE VARIABLE iOrdem        AS INTEGER   NO-UNDO.
    DEFINE VARIABLE lOk           AS LOGICAL   NO-UNDO.
    DEFINE VARIABLE iSituacao     AS INTEGER   NO-UNDO.
    DEFINE VARIABLE cSituacaoDesc AS CHARACTER NO-UNDO.
    
    EMPTY TEMP-TABLE tt-req-ord.
    
    ASSIGN
        cOrdemProducao = fi-ordem:SCREEN-VALUE IN FRAME fMain
        iOrdem         = INTEGER(cOrdemProducao) NO-ERROR.
        
   IF ERROR-STATUS:ERROR THEN
         ASSIGN iOrdem = -1.
    
   /*=============================================================
        VERIFICA SE A OP EH VALIDA
   ===============================================================*/ 
   
   RUN pi-valida-op (INPUT iOrdem, OUTPUT lOk).
   
   IF NOT lOk THEN
        RETURN.
        
   /*=============================================================
        VERIFICA SE VAI CRIAR OU SE JA EXISTE REGISTRO
        NA TABELA es_pesagem_mistura
   ===============================================================*/  
   
   RUN pi-cria-mistura (INPUT iOrdem).
        
   /*=============================================================
        PREENCHE CABECALHO
   ===============================================================*/

   RUN pi-devolve-situacao-op(INPUT iOrdem, OUTPUT iSituacao).
   
   // Traduz a situacao da OP, exemplo: 1 vira "PENDENTE"
   RUN pi-verificar-situacao (INPUT iSituacao, OUTPUT cSituacaoDesc).
   
   RUN pi-carrega-cabecalho (INPUT iOrdem, INPUT cSituacaoDesc).
   
   /*=============================================================  
        VERIFICA SE VAI CRIAR OU SE JA EXISTE REGISTRO
        NA TABELA es_pesagem_componente
   ===============================================================*/
   
   RUN pi-prepara-componentes (INPUT iOrdem).
   
   /*=============================================================
        MONTA tt-req-ord
        PREENCHE BROWSE br-itensReq
   ===============================================================*/
   
   RUN pi-prepara-itens-op (INPUT iOrdem).
      
   /*=============================================================
       VERIFICA SE VAI HABILITAR OU NAO BOTOES
   ===============================================================*/
   
   RUN pi-habilita-componentes   (INPUT cSituacaoDesc).
   
   /*=============================================================
        SE SITUACAO 'CONCLUIDO':
        MONTA tt-pesagem-item
        PREENCHE BROWSE brPesagem
   ===============================================================*/
   RUN pi-carrega-brPesagem (INPUT iOrdem).
   
    
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-carrega-brPesagem wWin 
PROCEDURE pi-carrega-brPesagem :
/*------------------------------------------------------------------------------
  PROCEDURE pi-carrega-brPesagem
  Purpose:     Monta a tt-pesagem-item e reabre o browse brPesagem.
  Parameters:  piOrdem (INPUT) - numero da ordem de producao
  Notes:       Um caminho so, valendo para a OP em qualquer situacao: monta o
               plano do que ha para pesar e sobrepoe o que ja foi pesado. OP
               concluida eh so o caso em que todo volume tem log aprovado.
               Quem monta eh quem limpa: sem o EMPTY, buscar uma segunda OP
               deixaria no browse as linhas da OP anterior.
               So linha concluida nasce marcada para impressao - o operador nao
               reimprime por acidente o que ainda nem foi pesado.
------------------------------------------------------------------------------*/
    DEFINE INPUT PARAMETER piOrdem AS INTEGER NO-UNDO.

    DEFINE VARIABLE cConcluido AS CHARACTER NO-UNDO.

    DEFINE BUFFER bf-vol FOR tt-pesagem-item.

    EMPTY TEMP-TABLE tt-pesagem-item.

    RUN pi-verificar-situacao (INPUT 3, OUTPUT cConcluido).

    RUN pi-monta-plano-pesagem.

    RUN pi-aplica-logs-pesagem (INPUT piOrdem).

    FOR EACH bf-vol:
        ASSIGN bf-vol.imprimir = (bf-vol.situacao = cConcluido).
    END.

    OPEN QUERY brPesagem FOR EACH tt-pesagem-item.

    RUN pi-habilita-btImprimir.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-carrega-cabecalho wWin 
PROCEDURE pi-carrega-cabecalho :
/*------------------------------------------------------------------------------
  Purpose:     Preenche o cabecalho da tela com os dados do item da ordem:
               fi-num-item, fi-item e fi-qtdOrdem-2.
  Parameters:  piOrdem (INPUT) - numero da ordem de producao
------------------------------------------------------------------------------*/
    DEFINE INPUT PARAMETER piOrdem        AS INTEGER NO-UNDO.
    DEFINE INPUT PARAMETER pcSituacaoDesc AS CHARACTER NO-UNDO.

    DEFINE BUFFER bf-ord  FOR ord-prod.
    DEFINE BUFFER bf-item FOR item.

    FIND FIRST bf-ord NO-LOCK
        WHERE bf-ord.nr-ord-produ = piOrdem
        NO-ERROR.

    IF NOT AVAILABLE bf-ord THEN
        RETURN.

    FIND FIRST bf-item NO-LOCK
        WHERE bf-item.it-codigo = bf-ord.it-codigo
        NO-ERROR.

    ASSIGN
        fi-num-item:SCREEN-VALUE   IN FRAME fMain = (IF AVAILABLE bf-item
                                                     THEN bf-item.it-codigo
                                                     ELSE "")
        fi-item:SCREEN-VALUE       IN FRAME fMain = (IF AVAILABLE bf-item
                                                     THEN bf-item.desc-item
                                                     ELSE bf-ord.it-codigo)
                                                     
        fi-qtdOrdem-2:SCREEN-VALUE IN FRAME fMain = STRING(bf-ord.qt-ordem,
                                                           "->>>,>>9.9999")
                                                           
        fi-situacao:SCREEN-VALUE IN FRAME fMain = pcSituacaoDesc.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-confirmar-pesagem wWin 
PROCEDURE pi-confirmar-pesagem :
/*------------------------------------------------------------------------------
  PROCEDURE pi-confirmar-pesagem
  Purpose:     Confirma o peso do volume corrente: valida, registra no log,
               grava, projeta o desvio, e encadeia o fechamento do componente
               e da mistura quando for o caso.
  Parameters:  <none>
  Notes:       O log eh gravado SEMPRE, aprovado ou nao.
               Fechando o componente, avanca sozinho para o proximo item e
               reposiciona os dois browses.
------------------------------------------------------------------------------*/
    DEFINE VARIABLE dPeso         AS DECIMAL   NO-UNDO.
    DEFINE VARIABLE iOrdem        AS INTEGER   NO-UNDO.
    DEFINE VARIABLE iResultado    AS INTEGER   NO-UNDO.
    DEFINE VARIABLE iSeqPesar     AS INTEGER   NO-UNDO.
    DEFINE VARIABLE iSituacao     AS INTEGER   NO-UNDO.
    DEFINE VARIABLE lOk           AS LOGICAL   NO-UNDO.
    DEFINE VARIABLE lEstourou     AS LOGICAL   NO-UNDO.
    DEFINE VARIABLE lItemFechou   AS LOGICAL   NO-UNDO.
    DEFINE VARIABLE lOPFechou     AS LOGICAL   NO-UNDO.
    DEFINE VARIABLE cAviso        AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cItemFechado  AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cDescOP       AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cSituacaoDesc AS CHARACTER NO-UNDO.
    DEFINE VARIABLE rVolume       AS ROWID     NO-UNDO.

    ASSIGN iOrdem = INTEGER(cOrdemProducao) NO-ERROR.

    IF ERROR-STATUS:ERROR THEN
        ASSIGN iOrdem = -1.

    // O primeiro item PENDENTE - tt-pesagem-item - browser de baixo
    RUN pi-volume-corrente (OUTPUT rVolume).

    IF rVolume = ? THEN DO:
        MESSAGE "Nenhum volume pendente para este item."
            VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.
        RETURN.
    END.

    ASSIGN dPeso = DECIMAL(fi-peso-item:SCREEN-VALUE IN FRAME fMain) NO-ERROR.

    IF ERROR-STATUS:ERROR THEN
        ASSIGN dPeso = 0.

    
    
    RUN pi-valida-peso-volume (INPUT  rVolume,
                               INPUT  dPeso,
                               OUTPUT lOk,
                               OUTPUT iResultado).

    RUN pi-grava-log-pesagem (INPUT iOrdem,
                              INPUT rVolume,
                              INPUT dPeso,
                              INPUT iResultado).

    IF NOT lOk THEN DO:
        APPLY "ENTRY" TO fi-peso-item IN FRAME fMain.
        RETURN.
    END.

    RUN pi-grava-peso-volume (INPUT iOrdem, INPUT rVolume, INPUT dPeso).

    RUN pi-projeta-desvio-componente (INPUT  iOrdem,
                                      INPUT  rVolume,
                                      OUTPUT cAviso,
                                      OUTPUT lEstourou).

    IF cAviso <> "" THEN DO:
        IF lEstourou THEN
            MESSAGE cAviso VIEW-AS ALERT-BOX ERROR   BUTTONS OK.
        ELSE
            MESSAGE cAviso VIEW-AS ALERT-BOX WARNING BUTTONS OK.
    END.

    RUN pi-fecha-componente (INPUT  iOrdem,
                             INPUT  rVolume,
                             OUTPUT lItemFechou,
                             OUTPUT cItemFechado).

    OPEN QUERY brPesagem FOR EACH tt-pesagem-item.

    /* ---- componente ainda em andamento: so vai para o proximo volume ---- */
    IF NOT lItemFechou THEN DO:

        RUN pi-pos-cursor-brPesagem.

        ASSIGN fi-peso-item:SCREEN-VALUE IN FRAME fMain = "0".
        APPLY "ENTRY" TO fi-peso-item IN FRAME fMain.
        RETURN.
    END.

    MESSAGE "ITEM " + cItemFechado + " PESADO COM EXITO!"
        VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.

    RUN pi-fecha-mistura (INPUT  iOrdem,
                          OUTPUT lOPFechou,
                          OUTPUT cDescOP).

    /* ---- OP inteira concluida ---- */
    IF lOPFechou THEN DO:

        MESSAGE "PESAGEM DO " + cDescOP + " FINALIZADA COM SUCESSO!"
            VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.

        RUN pi-devolve-situacao-op  (INPUT iOrdem, OUTPUT iSituacao).
        RUN pi-verificar-situacao   (INPUT iSituacao, OUTPUT cSituacaoDesc).

        ASSIGN fi-situacao:SCREEN-VALUE IN FRAME fMain = cSituacaoDesc.

        /* as duas temp-tables guardam a situacao de quando a OP foi buscada:
           sem remontar, os browses continuariam mostrando EM ANDAMENTO e
           PENDENTE depois de a OP ter fechado */
        RUN pi-prepara-itens-op     (INPUT iOrdem).
        RUN pi-carrega-brPesagem    (INPUT iOrdem).

        RUN pi-habilita-componentes (INPUT cSituacaoDesc).

        ASSIGN
            cItCodigo                                    = ""
            cDescItem                                    = ""
            fi-aviso-pesagem:SCREEN-VALUE IN FRAME fMain = ""
            fi-peso-item:SCREEN-VALUE     IN FRAME fMain = "0".

        DISABLE fi-peso-item btConfirmarPeso WITH FRAME fMain.
        RETURN.
    END.

    /* ---- avanca para o proximo componente ---- */
    RUN pi-verificar-item-nao-concluido (OUTPUT cItCodigo,
                                         OUTPUT cDescItem,
                                         OUTPUT iSeqPesar).

    RUN pi-pos-cursor-itensReq.
    RUN pi-pos-cursor-brPesagem.

    ASSIGN
        fi-aviso-pesagem:SCREEN-VALUE IN FRAME fMain = cDescItem
        fi-peso-item:SCREEN-VALUE     IN FRAME fMain = "0".

    APPLY "ENTRY" TO fi-peso-item IN FRAME fMain.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-cria-componentes wWin 
PROCEDURE pi-cria-componentes :
/*------------------------------------------------------------------------------
  Purpose:     Cria em es_pesagem_componente os itens da OP que ainda nao
               tem registro.
  Parameters:  piOrdem (INPUT) - numero da ordem de producao
  Notes:       Identidade do componente: nr_ordem + item + lote. Depende da
               tt-req-ord ja montada.
------------------------------------------------------------------------------*/
    DEFINE INPUT PARAMETER piOrdem AS INTEGER NO-UNDO.

    DEFINE BUFFER bf-ord   FOR ord-prod.
    DEFINE BUFFER bf-tt    FOR tt-req-ord.
    DEFINE BUFFER bf-comp  FOR es_pesagem_componente.
    DEFINE BUFFER bf-param FOR es_pesagem_param.
    
    /*=============================================================
        BUSCAR ord-prod
    ===============================================================*/

    FIND FIRST bf-ord NO-LOCK
        WHERE bf-ord.nr-ord-produ = piOrdem
        NO-ERROR.

    IF NOT AVAILABLE bf-ord THEN
        RETURN.

    FOR EACH bf-tt NO-LOCK:

        FIND FIRST bf-comp EXCLUSIVE-LOCK
            WHERE bf-comp.nr_ordem = piOrdem
              AND bf-comp.item     = bf-tt.it-codigo
              AND bf-comp.lote     = bf-tt.lote
            NO-ERROR.

        IF AVAILABLE bf-comp THEN
            NEXT.

        
        FIND FIRST bf-param NO-LOCK
            WHERE bf-param.item_pai   = bf-ord.it-codigo
              AND bf-param.item_filho = bf-tt.it-codigo
            NO-ERROR.

        CREATE bf-comp.

        ASSIGN
            bf-comp.nr_ordem                     = piOrdem
            bf-comp.item                         = bf-tt.it-codigo
            bf-comp.lote                         = bf-tt.lote
            bf-comp.qt_requisitada               = bf-tt.qt-requisitada
            bf-comp.capacidade_embalagem         = (IF AVAILABLE bf-param
                                                    THEN bf-param.capacidade_embalagem
                                                    ELSE 0)
            bf-comp.qt_pesada_balanca            = 0
            bf-comp.qt_embalagens_fechadas       = bf-tt.qt-embalagens
            bf-comp.qt_volumes                   = 0
            bf-comp.qt_desvio_requisitada_pesada = 0
            bf-comp.pc_desvio                    = 0
            bf-comp.qt_reimpressoes              = 0
            bf-comp.total_tentativas             = 0
            bf-comp.situacao                     = (IF bf-tt.qt-pesar < dPesoMinBalanca
                                                    THEN 3    /* CONCLUIDO - nada a pesar */
                                                    ELSE 2).  /* EM ANDAMENTO */
    END.

    RELEASE bf-comp.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-cria-linha-pesagem wWin 
PROCEDURE pi-cria-linha-pesagem :
/*------------------------------------------------------------------------------
  Purpose:     Cria uma linha na tt-pesagem-item - uma embalagem ou um volume
               a pesar.
  Parameters:  pcTipo     (INPUT) - "EMB. FECHADA" ou "PESAGEM"
               pcItCodigo (INPUT) - item do componente
               pcLote     (INPUT) - lote do componente
               pcDescItem (INPUT) - descricao do item
               pcUn       (INPUT) - unidade de medida
               piNumero   (INPUT) - numero sequencial dentro do tipo
               pdQuantid  (INPUT) - peso desta embalagem ou deste volume
               pcSituacao (INPUT) - situacao inicial da linha
------------------------------------------------------------------------------*/
    DEFINE INPUT PARAMETER pcTipo     AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER pcItCodigo AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER pcLote     AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER pcDescItem AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER pcUn       AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER piNumero   AS INTEGER   NO-UNDO.
    DEFINE INPUT PARAMETER pdQuantid  AS DECIMAL   NO-UNDO.
    DEFINE INPUT PARAMETER pcSituacao AS CHARACTER NO-UNDO.

    CREATE tt-pesagem-item.

    ASSIGN
        tt-pesagem-item.imprimir  = NO
        tt-pesagem-item.tipo      = pcTipo
        tt-pesagem-item.it-codigo = pcItCodigo
        tt-pesagem-item.lote      = pcLote
        tt-pesagem-item.desc-item = pcDescItem
        tt-pesagem-item.un        = pcUn
        tt-pesagem-item.qt-volume = piNumero
        tt-pesagem-item.qt-pesar  = pdQuantid
        tt-pesagem-item.qt-pesado = 0
        tt-pesagem-item.situacao  = pcSituacao.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-cria-mistura wWin 
PROCEDURE pi-cria-mistura :
/*------------------------------------------------------------------------------
  Purpose:     Cria o cabecalho da mistura (es_pesagem_mistura) desta OP quando
               ele ainda nao existe. Ja existindo, nao faz nada.
  Parameters:  piOrdem (INPUT) - numero da ordem de producao
  Notes:       Depende da tt-req-ord ja montada ? rodar depois de
               pi-monta-itens-req.
------------------------------------------------------------------------------*/
    DEFINE INPUT PARAMETER piOrdem AS INTEGER NO-UNDO.

    DEFINE VARIABLE iSituacaoPendente AS INTEGER   NO-UNDO INIT 1.
    DEFINE VARIABLE dtmAgora          AS DATETIME  NO-UNDO.
    DEFINE VARIABLE dtAgora           AS DATE      NO-UNDO.
    DEFINE VARIABLE cHrAgora          AS CHARACTER NO-UNDO.


    DEFINE VARIABLE iTotalComponentes AS INTEGER NO-UNDO.
    DEFINE VARIABLE dQtRequisitTotal  AS DECIMAL NO-UNDO.

    DEFINE BUFFER bf-ord     FOR ord-prod.
    DEFINE BUFFER bf-req     FOR req-ord.
    DEFINE BUFFER bf-mistura FOR es_pesagem_mistura.

    /* capturar AGORA */
    ASSIGN dtmAgora = NOW
           dtAgora  = DATE(dtmAgora)
           cHrAgora = STRING(INTEGER(MTIME(dtmAgora) / 1000), "HH:MM:SS").

    FIND FIRST bf-mistura NO-LOCK
        WHERE bf-mistura.nr_ordem = piOrdem
        NO-ERROR.

    IF AVAILABLE bf-mistura THEN
        RETURN.

    FIND FIRST bf-ord NO-LOCK
        WHERE bf-ord.nr-ord-produ = piOrdem
        NO-ERROR.

    IF NOT AVAILABLE bf-ord THEN
        RETURN.

    FOR EACH bf-req NO-LOCK
        WHERE bf-req.nr-ord-produ = piOrdem:
        ASSIGN
            iTotalComponentes = iTotalComponentes + 1
            dQtRequisitTotal  = dQtRequisitTotal + bf-req.qtd-requisitd-lote.
    END.

    CREATE bf-mistura.

    ASSIGN
        bf-mistura.balanca                        = cNomeBalanca
        bf-mistura.dt_fim                         = ?
        bf-mistura.dt_inicio                      = ?
        bf-mistura.hr_fim                         = ?
        bf-mistura.hr_inicio                      = ?
        bf-mistura.item_pai                       = bf-ord.it-codigo
        bf-mistura.nr_ordem                       = piOrdem
        bf-mistura.operador                       = ?
        bf-mistura.qt_desvio_requisitada_pesada   = 0
        bf-mistura.qt_ordem                       = bf-ord.qt-ordem
        bf-mistura.qt_pesada_total                = 0
        bf-mistura.qt_requisitada_total           = dQtRequisitTotal
        bf-mistura.situacao                       = iSituacaoPendente
        bf-mistura.total_componentes              = iTotalComponentes
        bf-mistura.total_componentes_pesados      = 0.

    RELEASE bf-mistura.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-devolve-situacao-op wWin 
PROCEDURE pi-devolve-situacao-op :
/*------------------------------------------------------------------------------
  Purpose:      Consulta a situa‡Æo da mistura de uma ordem de produ‡Æo.
  Parameters:   piOrdem    - N£mero da ordem de produ‡Æo.
                piSituacao - Situa‡Æo atual da mistura encontrada.
  Notes:        Retorna 0 quando nÆo existe registro de mistura para a ordem.
------------------------------------------------------------------------------*/
    DEFINE INPUT  PARAMETER piOrdem    AS INTEGER NO-UNDO.
    DEFINE OUTPUT PARAMETER piSituacao AS INTEGER NO-UNDO.

    DEFINE BUFFER bf-mistura FOR es_pesagem_mistura.

    FIND FIRST bf-mistura NO-LOCK
        WHERE bf-mistura.nr_ordem = piOrdem
        NO-ERROR.

    ASSIGN piSituacao = (IF AVAILABLE bf-mistura
                        THEN bf-mistura.situacao
                        ELSE 0).
    
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-fecha-componente wWin 
PROCEDURE pi-fecha-componente :
/*------------------------------------------------------------------------------
  PROCEDURE pi-fecha-componente
  Purpose:     Marca o componente como CONCLUIDO (situacao 3) quando nao sobra
               nenhum volume pendente dele na tt-pesagem-item.
  Parameters:  piOrdem    (INPUT)  - numero da ordem de producao
               prVolume   (INPUT)  - ROWID do volume recem confirmado
               plFechou   (OUTPUT) - TRUE quando o componente fechou agora
               pcDescItem (OUTPUT) - descricao do item que fechou
  Notes:       Rodar depois de pi-grava-peso-volume, que jah marcou a linha do
               volume como "OK".
------------------------------------------------------------------------------*/
    DEFINE INPUT  PARAMETER piOrdem    AS INTEGER   NO-UNDO.
    DEFINE INPUT  PARAMETER prVolume   AS ROWID     NO-UNDO.
    DEFINE OUTPUT PARAMETER plFechou   AS LOGICAL   NO-UNDO.
    DEFINE OUTPUT PARAMETER pcDescItem AS CHARACTER NO-UNDO.

    DEFINE BUFFER bf-vol  FOR tt-pesagem-item.
    DEFINE BUFFER bf-pend FOR tt-pesagem-item.
    DEFINE BUFFER bf-comp FOR es_pesagem_componente.
    DEFINE BUFFER bf-item FOR item.

    FIND bf-vol WHERE ROWID(bf-vol) = prVolume NO-ERROR.

    IF NOT AVAILABLE bf-vol THEN
        RETURN.

    /* ainda sobra volume a pesar deste componente? */
    FIND FIRST bf-pend NO-LOCK
        WHERE bf-pend.it-codigo = bf-vol.it-codigo
          AND bf-pend.lote      = bf-vol.lote
          AND bf-pend.tipo      = "PESAGEM"
          AND bf-pend.situacao  = "PENDENTE"
        NO-ERROR.

    IF AVAILABLE bf-pend THEN
        RETURN.

    FIND FIRST bf-comp EXCLUSIVE-LOCK
        WHERE bf-comp.nr_ordem = piOrdem
          AND bf-comp.item     = bf-vol.it-codigo
          AND bf-comp.lote     = bf-vol.lote
        NO-ERROR.

    IF NOT AVAILABLE bf-comp THEN
        RETURN.

    ASSIGN bf-comp.situacao = 3.  /* CONCLUIDO */

    RELEASE bf-comp.

    FIND FIRST bf-item NO-LOCK
        WHERE bf-item.it-codigo = bf-vol.it-codigo
        NO-ERROR.

    ASSIGN
        plFechou   = TRUE
        pcDescItem = (IF AVAILABLE bf-item
                      THEN CAPS(bf-item.desc-item)
                      ELSE bf-vol.it-codigo).

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-fecha-mistura wWin 
PROCEDURE pi-fecha-mistura :
/*------------------------------------------------------------------------------
  PROCEDURE pi-fecha-mistura
  Purpose:     Fecha o cabecalho da mistura quando TODOS os componentes da OP
               estao concluidos: grava totais, data/hora de fim e situacao 3.
  Parameters:  piOrdem  (INPUT)  - numero da ordem de producao
               plFechou (OUTPUT) - TRUE quando a mistura fechou agora
               pcDescOP (OUTPUT) - descricao do item pai da ordem
  Notes:       O total entregue soma as duas partes de cada componente:
               embalagens mais o que passou pela balanca.
------------------------------------------------------------------------------*/
    DEFINE INPUT  PARAMETER piOrdem  AS INTEGER   NO-UNDO.
    DEFINE OUTPUT PARAMETER plFechou AS LOGICAL   NO-UNDO.
    DEFINE OUTPUT PARAMETER pcDescOP AS CHARACTER NO-UNDO.

    DEFINE VARIABLE iConcluidos  AS INTEGER NO-UNDO.
    DEFINE VARIABLE dPesadaTot   AS DECIMAL NO-UNDO.
    DEFINE VARIABLE dEntregueTot AS DECIMAL NO-UNDO.

    DEFINE BUFFER bf-comp    FOR es_pesagem_componente.
    DEFINE BUFFER bf-mistura FOR es_pesagem_mistura.
    DEFINE BUFFER bf-ord     FOR ord-prod.
    DEFINE BUFFER bf-item    FOR item.

    /* algum componente ainda nao concluido? */
    FIND FIRST bf-comp NO-LOCK
        WHERE bf-comp.nr_ordem = piOrdem
          AND bf-comp.situacao <> 3
        NO-ERROR.

    IF AVAILABLE bf-comp THEN
        RETURN.

    FOR EACH bf-comp NO-LOCK
        WHERE bf-comp.nr_ordem = piOrdem:

        ASSIGN
            iConcluidos  = iConcluidos + 1
            dPesadaTot   = dPesadaTot + bf-comp.qt_pesada_balanca
            dEntregueTot = dEntregueTot
                         + (bf-comp.qt_embalagens_fechadas * bf-comp.capacidade_embalagem)
                         + bf-comp.qt_pesada_balanca.
    END.

    FIND FIRST bf-mistura EXCLUSIVE-LOCK
        WHERE bf-mistura.nr_ordem = piOrdem
        NO-ERROR.

    IF NOT AVAILABLE bf-mistura THEN
        RETURN.

    ASSIGN
        bf-mistura.qt_pesada_total              = dPesadaTot
        bf-mistura.total_componentes_pesados    = iConcluidos
        bf-mistura.qt_desvio_requisitada_pesada = bf-mistura.qt_requisitada_total
                                                - dEntregueTot
        bf-mistura.situacao                     = 3      /* CONCLUIDO */
        bf-mistura.dt_fim                       = TODAY
        bf-mistura.hr_fim                       = STRING(TIME, "HH:MM:SS").

    RELEASE bf-mistura.

    FIND FIRST bf-ord NO-LOCK
        WHERE bf-ord.nr-ord-produ = piOrdem
        NO-ERROR.

    IF AVAILABLE bf-ord THEN
        FIND FIRST bf-item NO-LOCK
            WHERE bf-item.it-codigo = bf-ord.it-codigo
            NO-ERROR.

    ASSIGN
        plFechou = TRUE
        pcDescOP = (IF AVAILABLE bf-item
                    THEN CAPS(bf-item.desc-item)
                    ELSE (IF AVAILABLE bf-ord THEN bf-ord.it-codigo ELSE "")).

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-grava-log-pesagem wWin 
PROCEDURE pi-grava-log-pesagem :
/*------------------------------------------------------------------------------
  PROCEDURE pi-grava-log-pesagem
  Purpose:     Registra a tentativa de pesagem em es_pesagem_log. Roda SEMPRE,
               com o peso aprovado ou recusado.
  Parameters:  piOrdem     (INPUT) - numero da ordem de producao
               prVolume    (INPUT) - ROWID do volume na tt-pesagem-item
               pdPeso      (INPUT) - peso informado
               pcResultado (INPUT) - desfecho devolvido pela validacao
  Notes:       tentativa eh sequencial dentro do ITEM na ordem, nao dentro do
               volume - exigencia do indice unico da tabela, explicada no corpo.
               total_tentativas do componente conta todas as tentativas,
               aprovadas ou nao - por isso eh incrementado aqui.
               O desvio do log eh contra o alvo do VOLUME, na mesma convencao
               de sinal do componente: alvo - pesado, negativo = pesou a mais.
------------------------------------------------------------------------------*/
    DEFINE INPUT PARAMETER piOrdem     AS INTEGER   NO-UNDO.
    DEFINE INPUT PARAMETER prVolume    AS ROWID     NO-UNDO.
    DEFINE INPUT PARAMETER pdPeso      AS DECIMAL   NO-UNDO.
    //DEFINE INPUT PARAMETER pcResultado AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER piResultado AS INTEGER   NO-UNDO.

    DEFINE VARIABLE iTentativa AS INTEGER NO-UNDO.
    DEFINE VARIABLE dDesvio    AS DECIMAL NO-UNDO.

    DEFINE BUFFER bf-vol  FOR tt-pesagem-item.
    DEFINE BUFFER bf-log  FOR es_pesagem_log.
    DEFINE BUFFER bf-cont FOR es_pesagem_log.
    DEFINE BUFFER bf-comp FOR es_pesagem_componente.

    FIND bf-vol WHERE ROWID(bf-vol) = prVolume NO-ERROR.

    IF NOT AVAILABLE bf-vol THEN
        RETURN.

    /* Numero da tentativa: sequencial dentro do ITEM na ordem, e NAO dentro do
       volume. O indice unico da es_pesagem_log nao inclui o campo volume - ele
       foi acrescentado a tabela depois que o indice ja existia - entao numerar
       por volume fazia o volume 2 nascer com tentativa 1 e bater de frente com
       o volume 1, estourando "unique constraint violated" na confirmacao.
       Contar por ordem + item, sem lote e sem volume, mantem o numero unico sob
       qualquer composicao de indice que inclua tentativa. */
    FOR EACH bf-cont NO-LOCK
        WHERE bf-cont.nr_ordem = piOrdem
          AND bf-cont.item     = bf-vol.it-codigo:
        ASSIGN iTentativa = iTentativa + 1.
    END.

    ASSIGN
        iTentativa = iTentativa + 1
        dDesvio    = bf-vol.qt-pesar - pdPeso.

    FIND FIRST bf-comp EXCLUSIVE-LOCK
        WHERE bf-comp.nr_ordem = piOrdem
          AND bf-comp.item     = bf-vol.it-codigo
          AND bf-comp.lote     = bf-vol.lote
        NO-ERROR.

    CREATE bf-log.

    ASSIGN
        bf-log.nr_ordem   = piOrdem
        bf-log.item       = bf-vol.it-codigo
        bf-log.lote       = bf-vol.lote
        bf-log.sequencia  = (IF AVAILABLE bf-comp THEN bf-comp.sequencia ELSE 0)
        bf-log.volume     = bf-vol.qt-volume
        bf-log.tentativa  = iTentativa
        bf-log.peso       = pdPeso
        bf-log.qt_desvio  = dDesvio
        bf-log.pc_desvio  = (IF bf-vol.qt-pesar > 0
                             THEN dDesvio / bf-vol.qt-pesar * 100
                             ELSE 0)
        bf-log.resultado  = piResultado  //int(pcResultado)
        bf-log.dt_pesagem = TODAY
        bf-log.hr_pesagem = STRING(TIME, "HH:MM:SS").

    IF AVAILABLE bf-comp THEN
        ASSIGN bf-comp.total_tentativas = bf-comp.total_tentativas + 1.

    RELEASE bf-log.
    RELEASE bf-comp.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-grava-peso-volume wWin 
PROCEDURE pi-grava-peso-volume :
/*------------------------------------------------------------------------------
  PROCEDURE pi-grava-peso-volume
  Purpose:     Grava o peso aprovado na linha do volume e acumula no
               componente, recalculando desvio em quantidade e em percentual.
  Parameters:  piOrdem  (INPUT) - numero da ordem de producao
               prVolume (INPUT) - ROWID do volume na tt-pesagem-item
               pdPeso   (INPUT) - peso confirmado
  Notes:       O total entregue reconstroi as duas partes: embalagens
               (qt_embalagens_fechadas * capacidade_embalagem) mais o que
               passou pela balanca (qt_pesada_balanca).
               Sinal: requisitada - entregue, NEGATIVO = pesou a mais.
               total_tentativas nao eh mexido aqui - quem conta eh o log.
------------------------------------------------------------------------------*/
    DEFINE INPUT PARAMETER piOrdem  AS INTEGER NO-UNDO.
    DEFINE INPUT PARAMETER prVolume AS ROWID   NO-UNDO.
    DEFINE INPUT PARAMETER pdPeso   AS DECIMAL NO-UNDO.

    DEFINE VARIABLE dEntregue  AS DECIMAL   NO-UNDO.
    DEFINE VARIABLE dDesvio    AS DECIMAL   NO-UNDO.
    DEFINE VARIABLE cConcluido AS CHARACTER NO-UNDO.

    DEFINE BUFFER bf-vol  FOR tt-pesagem-item.
    DEFINE BUFFER bf-comp FOR es_pesagem_componente.

    FIND bf-vol WHERE ROWID(bf-vol) = prVolume NO-ERROR.

    IF NOT AVAILABLE bf-vol THEN
        RETURN.

    /* o texto vem da pi-verificar-situacao, nunca de literal: eh com ele que a
       pi-imprimir-etiquetas decide o que entra na impressao */
    RUN pi-verificar-situacao (INPUT 3, OUTPUT cConcluido).

    ASSIGN
        bf-vol.qt-pesado = pdPeso
        bf-vol.situacao  = cConcluido.

    FIND FIRST bf-comp EXCLUSIVE-LOCK
        WHERE bf-comp.nr_ordem = piOrdem
          AND bf-comp.item     = bf-vol.it-codigo
          AND bf-comp.lote     = bf-vol.lote
        NO-ERROR.

    IF NOT AVAILABLE bf-comp THEN
        RETURN.

    ASSIGN
        bf-comp.qt_pesada_balanca = bf-comp.qt_pesada_balanca + pdPeso

        dEntregue = (bf-comp.qt_embalagens_fechadas * bf-comp.capacidade_embalagem)
                    + bf-comp.qt_pesada_balanca

        dDesvio   = bf-comp.qt_requisitada - dEntregue

        bf-comp.qt_desvio_requisitada_pesada = dDesvio

        bf-comp.pc_desvio = (IF bf-comp.qt_requisitada > 0
                             THEN dDesvio / bf-comp.qt_requisitada * 100
                             ELSE 0)

        bf-comp.dt_pesagem = TODAY
        bf-comp.hr_pesagem = STRING(TIME, "HH:MM:SS").

    RELEASE bf-comp.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-habilita-btImprimir wWin 
PROCEDURE pi-habilita-btImprimir :
/*------------------------------------------------------------------------------
  PROCEDURE pi-habilita-btImprimir
  Purpose:     Liga o botao Imprimir quando existe pelo menos uma linha marcada
               no brPesagem, e desliga quando nao ha nenhuma.
  Parameters:  <none>
  Notes:       Usa buffer proprio para nao mexer no buffer que o browse usa.
               Chamar sempre que o conjunto de marcados mudar: no VALUE-CHANGED
               da coluna, nos botoes Marcar e Todos, e depois de recarregar a
               tt-pesagem-item.
------------------------------------------------------------------------------*/
    DEFINE BUFFER bf-vol FOR tt-pesagem-item.

    ASSIGN btImprimir:SENSITIVE IN FRAME fMain =
        CAN-FIND(FIRST bf-vol WHERE bf-vol.imprimir = YES).

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-habilita-componentes wWin 
PROCEDURE pi-habilita-componentes :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
     DEFINE INPUT PARAMETER pcSituacaoDesc AS CHARACTER NO-UNDO.
     
    /*=============================================================
        VERIFICA SE A OP ESTA CONCLUIDA
        Se concluida, desabilita o botao de pesagem e libera o
        br-itensReq. Quem manda no botao Imprimir eh pi-habilita-btImprimir.
    =============================================================*/
    IF pcSituacaoDesc = "CONCLUIDO" THEN DO:
        ASSIGN
            bt-pesagem:SENSITIVE IN FRAME fMain = FALSE
            br-itensReq:SENSITIVE = TRUE.
    END.
    ELSE DO:
        /*=============================================================
            OP AINDA NAO CONCLUIDA
            Habilita o botao de pesagem e trava o br-itensReq.
        =============================================================*/
        ASSIGN
            bt-pesagem:SENSITIVE IN FRAME fMain = TRUE
            br-itensReq:SENSITIVE = FALSE.
    END.
     
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-imprimir-etiquetas wWin 
PROCEDURE pi-imprimir-etiquetas :
/*------------------------------------------------------------------------------
  PROCEDURE pi-imprimir-etiquetas
  Purpose:     Abre a selecao de impressora e gera uma etiqueta para cada linha
               marcada e concluida do brPesagem.
  Parameters:  <none>
  Notes:       Usa buffer proprio (bf-vol) - percorrer com o buffer default
               dessincronizaria a linha destacada do browse.
               O texto de comparacao vem da pi-verificar-situacao, nunca de
               literal.
               iElegiveis eh quanto DA para imprimir; iImpressas eh quanto foi
               realmente escrito, contado DENTRO do laco. Antes um contador so
               fazia os dois papeis, e a mensagem final anunciava como impresso
               o que era apenas elegivel.
               A mensagem fala em "enviadas", e nao "impressas", de proposito:
               cancelar dentro do driver (a janela de salvar PDF, por exemplo)
               nao volta para o Progress, entao o programa nao tem como afirmar
               que saiu papel. O que ele sabe eh o que mandou.
------------------------------------------------------------------------------*/
    DEFINE VARIABLE cConcluido AS CHARACTER NO-UNDO.
    DEFINE VARIABLE iMarcadas  AS INTEGER   NO-UNDO.
    DEFINE VARIABLE iElegiveis AS INTEGER   NO-UNDO.
    DEFINE VARIABLE iImpressas AS INTEGER   NO-UNDO.
    DEFINE VARIABLE lOk        AS LOGICAL   NO-UNDO.

    DEFINE BUFFER bf-vol FOR tt-pesagem-item.

    RUN pi-verificar-situacao (INPUT 3, OUTPUT cConcluido).

    FOR EACH bf-vol NO-LOCK
        WHERE bf-vol.imprimir = YES:

        ASSIGN iMarcadas = iMarcadas + 1.

        IF bf-vol.situacao = cConcluido THEN
            ASSIGN iElegiveis = iElegiveis + 1.
    END.

    /* Nao marcou nenhuma linha */
    IF iMarcadas = 0 THEN DO:
        MESSAGE "Nenhuma linha marcada para imprimir."
            VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.
        RETURN.
    END.

    /* Nao marcou nenhuma linha concluida */
    IF iElegiveis = 0 THEN DO:
        MESSAGE "Por favor, selecione ao menos um documento com situacao CONCLUIDA."
            VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.
        RETURN.
    END.

    SYSTEM-DIALOG PRINTER-SETUP UPDATE lOk.

    /* cancelou a escolha da impressora: nada foi gerado, e nao ha o que anunciar */
    IF NOT lOk THEN
        RETURN.

    DO ON ERROR UNDO, LEAVE:

        OUTPUT TO PRINTER PAGED.

        FOR EACH bf-vol NO-LOCK
            WHERE bf-vol.imprimir = YES
              AND bf-vol.situacao = cConcluido:

            RUN pi-monta-etiqueta (INPUT ROWID(bf-vol)).

            ASSIGN iImpressas = iImpressas + 1.

            PAGE.
        END.
    END.

    /* fora do bloco: fecha a saida mesmo se ela falhou no meio do laco */
    OUTPUT CLOSE.

    IF iImpressas = 0 THEN DO:
        MESSAGE "Nao foi possivel enviar as etiquetas para a impressora."
            VIEW-AS ALERT-BOX ERROR BUTTONS OK.
        RETURN.
    END.

    MESSAGE "Etiquetas enviadas para a impressora:" iImpressas
        VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-iniciar-pesagem wWin 
PROCEDURE pi-iniciar-pesagem :
/*------------------------------------------------------------------------------
  Purpose:     Inicia a pesagem: valida se a OP esta apta, localiza o proximo
               item a pesar, posiciona o browse nele e libera os campos de peso.
  Parameters:  <none>
------------------------------------------------------------------------------*/
    DEFINE VARIABLE iOrdem    AS INTEGER NO-UNDO.
    DEFINE VARIABLE iSeqPesar AS INTEGER NO-UNDO.
    DEFINE VARIABLE lOk       AS LOGICAL NO-UNDO.

    ASSIGN iOrdem = INTEGER(cOrdemProducao) NO-ERROR.

    /* Se nao conseguiu converter o valor de cOrdemProducao assume -1 */
    IF ERROR-STATUS:ERROR THEN
        ASSIGN iOrdem = -1.

    /*-----------------------------------------------------------------------------
        VERIFICAR SE A OP PODE INICIAR A PESAGEM
    -------------------------------------------------------------------------------*/ 
    RUN pi-valida-inicio-pesagem (INPUT iOrdem, OUTPUT lOk).

    IF NOT lOk THEN
        RETURN.

    /*-----------------------------------------------------------------------------
        AVISA O QUE O OPERADOR TEM DE SEPARAR A MAO ANTES DE COMECAR
    -------------------------------------------------------------------------------*/ 
    RUN pi-avisa-embalagens.

    /*-----------------------------------------------------------------------------
        CAPTURA ITEM QUE AINDA NAO FOI PESADO
    -------------------------------------------------------------------------------*/ 
    RUN pi-verificar-item-nao-concluido (OUTPUT cItCodigo,
                                         OUTPUT cDescItem,
                                         OUTPUT iSeqPesar).

    /*-----------------------------------------------------------------------------
        POSICIONA br-itensReq no primeiro item encontrado que ainda n foi pesado
    -------------------------------------------------------------------------------*/ 
    RUN pi-pos-cursor-itensReq.

    /*-----------------------------------------------------------------------------
        Povoar browser brPesagem
    -------------------------------------------------------------------------------*/ 

    // --- percorre tt-req-ord ---
    FOR EACH tt-req-ord NO-LOCK:

        CREATE tt-pesagem-item.
        // --- Se o item ja foi pesado, coloca no browser brPesagem ---
        IF tt-req-ord.situacao = "CONCLUIDO" THEN DO:
            ASSIGN
                tt-pesagem-item.imprimir = YES
                .   
        END.
        ELSE DO:
            ASSIGN
                   tt-pesagem-item.imprimir = NO
                   //tt-pesagem-item.it-codigo
                   //tt-pesagem-item.desc-item
                    .
        END.

    END.

    IF cItCodigo = "" THEN DO:
        MESSAGE "Nenhum item EM ATENDIMENTO nesta OP."
            VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.
        RETURN.
    END.

    /*-----------------------------------------------------------------------------
        LIBERA OS CAMPOS DE PESAGEM
    -------------------------------------------------------------------------------*/ 
    RUN pi-libera-campos-peso (INPUT cDescItem).

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-le-balan‡a wWin 
PROCEDURE pi-le-balan‡a :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-libera-campos-peso wWin 
PROCEDURE pi-libera-campos-peso :
/*------------------------------------------------------------------------------
  Purpose:     Mostra o item a ser pesado em fi-aviso-pesagem e libera os
               controles de digitacao do peso.
  Parameters:  pcDescItem (INPUT) - descricao do item que sera pesado
  Notes:       Nao acessa banco - pode ser chamada de qualquer ponto da tela.
------------------------------------------------------------------------------*/
    DEFINE INPUT PARAMETER pcDescItem AS CHARACTER NO-UNDO.

    ASSIGN fi-aviso-pesagem:SCREEN-VALUE IN FRAME fMain = pcDescItem.

    ENABLE fi-peso-item btConfirmarPeso WITH FRAME fMain.

    APPLY "ENTRY" TO fi-peso-item IN FRAME fMain.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-limpa-tela wWin 
PROCEDURE pi-limpa-tela :
/*------------------------------------------------------------------------------
  Purpose:  Limpa os dados da tela, os itens requisitados e desabilita os
            controles de pesagem.

  Parameters:
      <none>

  Notes:    Limpa a TEMP-TABLE tt-req-ord e atualiza o browser br-itensReq.
            Os controles relacionados a pesagem permanecem desabilitados
            at‚ que sejam habilitados pelo fluxo da tela.
------------------------------------------------------------------------------*/

EMPTY TEMP-TABLE tt-req-ord.

ASSIGN
    fi-ordem:SCREEN-VALUE          IN FRAME fMain = ""
    fi-num-item:SCREEN-VALUE       IN FRAME fMain = ""
    fi-item:SCREEN-VALUE           IN FRAME fMain = ""
    fi-qtdOrdem-2:SCREEN-VALUE     IN FRAME fMain = ""
    fi-situacao:SCREEN-VALUE       IN FRAME fMain = ""
    fi-aviso-pesagem:SCREEN-VALUE  IN FRAME fMain = ""
    fi-peso-item:SCREEN-VALUE      IN FRAME fMain = ""
    fi-peso-item:SENSITIVE       IN FRAME fMain = FALSE
    btConfirmarPeso:SENSITIVE    IN FRAME fMain = FALSE
    bt-pesagem:SENSITIVE         IN FRAME fMain = FALSE.
    
br-itensReq:QUERY:QUERY-CLOSE().
br-itensReq:QUERY:QUERY-PREPARE("FOR EACH tt-req-ord").
br-itensReq:QUERY:QUERY-OPEN().

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-monta-etiqueta wWin 
PROCEDURE pi-monta-etiqueta :
/*------------------------------------------------------------------------------
  PROCEDURE pi-monta-etiqueta
  Purpose:     Desenha UMA etiqueta na saida corrente.
  Parameters:  prVolume (INPUT) - ROWID da linha da tt-pesagem-item
  Notes:       Nao abre nem fecha OUTPUT, e nao dah PAGE - quem controla isso
               eh a pi-imprimir-etiquetas. Assim dah para testar o layout com
               OUTPUT TO "C:/temp/etiqueta.txt" sem gastar papel.
               A descricao eh truncada no que sobra da largura, para o codigo
               do item nunca ser cortado.
------------------------------------------------------------------------------*/
    DEFINE INPUT PARAMETER prVolume AS ROWID NO-UNDO.

    DEFINE VARIABLE iOrdem    AS INTEGER   NO-UNDO.
    DEFINE VARIABLE iSobra    AS INTEGER   NO-UNDO.
    DEFINE VARIABLE iTotalVol AS INTEGER   NO-UNDO.
    DEFINE VARIABLE dPeso     AS DECIMAL   NO-UNDO.
    DEFINE VARIABLE cSepDupla AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cSepSimpl AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cLinha    AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cDireita  AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cCodPai   AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cDescPai  AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cValidade AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cDataHora AS CHARACTER NO-UNDO.

    DEFINE BUFFER bf-vol  FOR tt-pesagem-item.
    DEFINE BUFFER bf-tt   FOR tt-req-ord.
    DEFINE BUFFER bf-ord  FOR ord-prod.
    DEFINE BUFFER bf-item FOR item.
    DEFINE BUFFER bf-log  FOR es_pesagem_log.
    DEFINE BUFFER bf-cnt  FOR tt-pesagem-item.

    FIND bf-vol WHERE ROWID(bf-vol) = prVolume NO-ERROR.

    IF NOT AVAILABLE bf-vol THEN
        RETURN.

    ASSIGN iOrdem = INTEGER(cOrdemProducao) NO-ERROR.

    IF ERROR-STATUS:ERROR THEN
        ASSIGN iOrdem = -1.

    ASSIGN
        cSepDupla = FILL("=", iLarguraEtiqueta)
        cSepSimpl = FILL("-", iLarguraSepSimp).

    /* ---- item pai da ordem ---- */
    FIND FIRST bf-ord NO-LOCK
        WHERE bf-ord.nr-ord-produ = iOrdem
        NO-ERROR.

    IF AVAILABLE bf-ord THEN DO:

        ASSIGN cCodPai = TRIM(bf-ord.it-codigo).

        FIND FIRST bf-item NO-LOCK
            WHERE bf-item.it-codigo = bf-ord.it-codigo
            NO-ERROR.

        IF AVAILABLE bf-item THEN
            ASSIGN cDescPai = CAPS(TRIM(bf-item.desc-item)).
    END.

    /* ---- validade do lote ---- */
    FIND FIRST bf-tt NO-LOCK
        WHERE bf-tt.it-codigo = bf-vol.it-codigo
          AND bf-tt.lote      = bf-vol.lote
        NO-ERROR.

    IF AVAILABLE bf-tt AND bf-tt.valid-lote <> ? THEN
        ASSIGN cValidade = STRING(bf-tt.valid-lote, "99/99/9999").

    /* ---- data e hora da pesagem deste volume ----
       so linha de PESAGEM tem log. Sem esta guarda, a EMB. FECHADA numero 2
       pegaria a data do volume 2 pesado do mesmo item e lote */
    IF bf-vol.tipo = "PESAGEM" THEN
    FOR EACH bf-log NO-LOCK
        WHERE bf-log.nr_ordem  = iOrdem
          AND bf-log.item      = bf-vol.it-codigo
          AND bf-log.lote      = bf-vol.lote
          AND bf-log.volume    = bf-vol.qt-volume
          AND bf-log.resultado = 1
        BY bf-log.tentativa:

        ASSIGN cDataHora = STRING(bf-log.dt_pesagem, "99/99/99")
                         + " " + SUBSTRING(bf-log.hr_pesagem, 1, 5).
    END.

    /* linha de EMB. FECHADA nao tem log: usa o momento da impressao */
    IF cDataHora = "" THEN
        ASSIGN cDataHora = STRING(TODAY, "99/99/99")
                         + " " + STRING(TIME, "HH:MM").

    /* volume usa o peso medido; embalagem usa o nominal */
    ASSIGN dPeso = (IF bf-vol.qt-pesado > 0
                    THEN bf-vol.qt-pesado
                    ELSE bf-vol.qt-pesar).

    /* ---- X/Y do cabecalho ----
       quantos volumes deste mesmo item, lote e tipo o plano previu. Nao
       depende do que foi marcado para imprimir: a etiqueta do volume 2 diz
       2/2 mesmo quando impressa sozinha */
    FOR EACH bf-cnt NO-LOCK
        WHERE bf-cnt.it-codigo = bf-vol.it-codigo
          AND bf-cnt.lote      = bf-vol.lote
          AND bf-cnt.tipo      = bf-vol.tipo:

        ASSIGN iTotalVol = iTotalVol + 1.
    END.

    /* ================= desenho ================= */

    PUT UNFORMATTED cSepDupla SKIP.

    ASSIGN
        cDireita = cDataHora 
                 + " " 
                 + "-" 
                 + " "
                 + TRIM(STRING(bf-vol.qt-volume, ">>>9"))
                 + "/" + TRIM(STRING(iTotalVol, ">>>9"))
        cLinha   = " OP " + TRIM(cOrdemProducao)
        cLinha   = cLinha
                 + FILL(" ", MAXIMUM(iLarguraEtiqueta - LENGTH(cLinha)
                                                      - LENGTH(cDireita), 1))
                 + cDireita.

    PUT UNFORMATTED cLinha    SKIP.
    PUT UNFORMATTED cSepDupla SKIP.

    ASSIGN
        cDireita = " -  Item pai: " + cCodPai
        iSobra   = MAXIMUM(iLarguraEtiqueta - 1 - LENGTH(cDireita), 1)
        cLinha   = " " + SUBSTRING(cDescPai, 1, iSobra) + cDireita.

    PUT UNFORMATTED cLinha    SKIP.
    PUT UNFORMATTED cSepSimpl SKIP.

    ASSIGN
        cDireita = " - Item ...: " + TRIM(bf-vol.it-codigo)
        iSobra   = MAXIMUM(iLarguraEtiqueta - 1 - LENGTH(cDireita), 1)
        cLinha   = " " + SUBSTRING(CAPS(TRIM(bf-vol.desc-item)), 1, iSobra)
                 + cDireita.

    PUT UNFORMATTED cLinha SKIP.

    ASSIGN cLinha = " Lote: " + TRIM(bf-vol.lote).

    IF cValidade <> "" THEN
        ASSIGN cLinha = cLinha + " - Validade: " + cValidade.

    PUT UNFORMATTED cLinha    SKIP.
    PUT UNFORMATTED cSepSimpl SKIP.

    /* montadas em cLinha como as demais: PUT UNFORMATTED com varias
       expressoes aplica o formato de cada uma e desalinha na impressora */
    ASSIGN cLinha = " Tipo ...: " + TRIM(bf-vol.tipo).

    PUT UNFORMATTED cLinha SKIP.

    ASSIGN cLinha = " Peso ...: " + TRIM(STRING(dPeso, "->>>,>>9.9999"))
                  + " " + TRIM(bf-vol.un).

    PUT UNFORMATTED cLinha SKIP.

    PUT UNFORMATTED cSepDupla SKIP.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-monta-itens-req wWin 
PROCEDURE pi-monta-itens-req :
/*------------------------------------------------------------------------------
  pi-monta-itens-req
  Purpose:     Monta a tt-req-ord com um registro por item requisitado da OP e
               reabre o browse br-itensReq.
  Parameters:  piOrdem (INPUT) - numero da ordem de producao
  Notes:       qt-embalagens = embalagens cheias; qt-pesar = sobra fracionada,
               que vai para a balanca. Sem es_pesagem_param cadastrado, o item
               inteiro vai para a balanca.
               A situacao vem de es_pesagem_componente, traduzida por
               pi-verificar-situacao. Sem componente gravado ainda, assume
               "EM ANDAMENTO".
------------------------------------------------------------------------------*/
    DEFINE INPUT PARAMETER piOrdem AS INTEGER NO-UNDO.   // 1025858

    DEFINE VARIABLE cSituacaoDesc AS CHARACTER NO-UNDO.

    DEFINE BUFFER bf-ord    FOR ord-prod.
    DEFINE BUFFER bf-req    FOR req-ord.
    DEFINE BUFFER bf-item   FOR item.
    DEFINE BUFFER bf-estrut FOR estrutura.
    DEFINE BUFFER bf-saldo  FOR saldo-estoq.
    DEFINE BUFFER bf-param  FOR es_pesagem_param.
    DEFINE BUFFER bf-comp   FOR es_pesagem_componente.

    /*------------------------------------------------------------------------------
        Localiza a ordem de produ‡Æo
    ------------------------------------------------------------------------------*/
    
    FIND FIRST bf-ord NO-LOCK
        WHERE bf-ord.nr-ord-produ = piOrdem
        NO-ERROR.

    IF NOT AVAILABLE bf-ord THEN
        RETURN.

        
    /*------------------------------------------------------------------------------
        Monta os itens requisitados da ordem
    ------------------------------------------------------------------------------*/
    FOR EACH bf-req NO-LOCK
        WHERE bf-req.nr-ord-produ = piOrdem:

        /* descricao e unidade */
        FIND FIRST bf-item NO-LOCK
            WHERE bf-item.it-codigo = bf-req.it-codigo
            NO-ERROR.

        /* quantidade da receita */
        FIND FIRST bf-estrut NO-LOCK
            WHERE bf-estrut.it-codigo = bf-ord.it-codigo
              AND bf-estrut.es-codigo = bf-req.it-codigo 
            NO-ERROR.

        /* validade do lote */
        FIND FIRST bf-saldo NO-LOCK
            WHERE bf-saldo.num-id-saldo-estoq = bf-req.num-id-saldo-estoq
            NO-ERROR.

        /* capacidade de embalagem */
        FIND FIRST bf-param NO-LOCK
            WHERE bf-param.item_pai   = bf-ord.it-codigo
              AND bf-param.item_filho = bf-req.it-codigo
            NO-ERROR.

        /* situacao ja gravada para este item */
        FIND FIRST bf-comp NO-LOCK
            WHERE bf-comp.nr_ordem = piOrdem
              AND bf-comp.item     = bf-req.it-codigo
              AND bf-comp.lote     = bf-req.lote-serie
            NO-ERROR.

        IF AVAILABLE bf-comp THEN
            RUN pi-verificar-situacao (INPUT  bf-comp.situacao,
                                       OUTPUT cSituacaoDesc).
        ELSE
            ASSIGN cSituacaoDesc = "EM ANDAMENTO".

        /*------------------------------------------------------------------------------
            Cria o registro da temp-table
        ------------------------------------------------------------------------------*/
        CREATE tt-req-ord.

        ASSIGN
            tt-req-ord.it-codigo      = bf-req.it-codigo
            tt-req-ord.lote           = bf-req.lote-serie
            tt-req-ord.qt-requisitada = bf-req.qtd-requisitd-lote
            tt-req-ord.situacao       = cSituacaoDesc
            
            tt-req-ord.capacidade     = (IF AVAILABLE bf-param
                                         THEN bf-param.capacidade_embalagem
                                         ELSE 0)

            tt-req-ord.un             = (IF AVAILABLE bf-item
                                         THEN bf-item.un
                                         ELSE "")

            tt-req-ord.desc-item      = (IF AVAILABLE bf-item
                                         THEN bf-item.desc-item
                                         ELSE "")

            tt-req-ord.valid-lote     = (IF AVAILABLE bf-saldo
                                         THEN bf-saldo.dt-vali-lote
                                         ELSE ?)

            tt-req-ord.qt-receita     = (IF AVAILABLE bf-estrut
                                         THEN bf-estrut.quant-usada * bf-ord.qt-ordem // ?
                                         ELSE 0)

            tt-req-ord.qt-embalagens  = (IF AVAILABLE bf-param
                                            AND bf-param.capacidade_embalagem > 0
                                         THEN TRUNCATE(bf-req.qtd-requisitd-lote /
                                                       bf-param.capacidade_embalagem, 0)
                                         ELSE 0)
                                              
            tt-req-ord.qt-pesar       = (IF AVAILABLE bf-param
                                            AND bf-param.capacidade_embalagem > 0
                                         THEN bf-req.qtd-requisitd-lote -
                                              (TRUNCATE(bf-req.qtd-requisitd-lote /
                                                        bf-param.capacidade_embalagem, 0)
                                               * bf-param.capacidade_embalagem)
                                         ELSE bf-req.qtd-requisitd-lote).
    END.

    /*------------------------------------------------------------------------------
        Atualiza o browse
    ------------------------------------------------------------------------------*/
    {&OPEN-QUERY-br-itensReq}

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-monta-plano-pesagem wWin 
PROCEDURE pi-monta-plano-pesagem :
/*------------------------------------------------------------------------------
  PROCEDURE pi-monta-plano-pesagem
  Purpose:     Monta na tt-pesagem-item o PLANO da OP: tudo que o operador tem
               de juntar, uma linha por componente embalado e uma por volume.
  Parameters:  <none>
  Notes:       Nao olha historico - quem marca o que ja foi pesado eh a
               pi-aplica-logs-pesagem, que roda logo depois.
               Peso sempre em KG. Depende da tt-req-ord montada, entao rodar
               depois de pi-prepara-itens-op.
               EMBALAGEM eh UMA linha por componente: qt-volume guarda a
               CONTAGEM de embalagens e qt-pesar o peso de UMA delas.
               Volume abaixo de dPesoMinBalanca ja nasce concluido - o operador
               separa a olho, aquilo nao vai a balanca.
               Sobra menor que o minimo eh somada no ultimo volume cheio, em
               vez de virar uma linha impesavel.
------------------------------------------------------------------------------*/
    DEFINE VARIABLE cConcluido     AS CHARACTER NO-UNDO.
    DEFINE VARIABLE iVolumesCheios AS INTEGER   NO-UNDO.
    DEFINE VARIABLE iContador      AS INTEGER   NO-UNDO.
    DEFINE VARIABLE dResto         AS DECIMAL   NO-UNDO.
    DEFINE VARIABLE dUltimoCheio   AS DECIMAL   NO-UNDO.
    DEFINE VARIABLE dQtVolume      AS DECIMAL   NO-UNDO.
    DEFINE VARIABLE iEmbalagens    AS INTEGER   NO-UNDO.
    DEFINE VARIABLE cAvisoParam    AS CHARACTER NO-UNDO.
    DEFINE VARIABLE iMaxEmbalagens AS INTEGER   NO-UNDO INITIAL 500. /* teto de seguranca */

    DEFINE BUFFER bf-tt FOR tt-req-ord.

    RUN pi-verificar-situacao (INPUT 3, OUTPUT cConcluido).

    FOR EACH bf-tt NO-LOCK:

        /* ---- embalagem fechada: UMA linha por embalagem fisica ----
           3 embalagens de 5 KG viram 3 linhas, numeradas 1..3 em qt-volume,
           cada uma com qt-pesar = 5 e cada uma rendendo sua etiqueta */
        ASSIGN iEmbalagens = INTEGER(bf-tt.qt-embalagens).

        /* capacidade errada (0,001 KG num item de 50 KG) daria dezenas de
           milhares de linhas e travaria a tela - ja aconteceu antes */
        IF iEmbalagens > iMaxEmbalagens THEN
            ASSIGN cAvisoParam = cAvisoParam + CHR(10)
                               + "   " + TRIM(bf-tt.it-codigo)
                               + ": " + TRIM(STRING(iEmbalagens, ">>>,>>>,>>9"))
                               + " embalagens de "
                               + TRIM(STRING(bf-tt.capacidade, "->>>,>>9.9999"))
                               + " KG"
                   iEmbalagens = iMaxEmbalagens.

        DO iContador = 1 TO iEmbalagens:

            RUN pi-cria-linha-pesagem (INPUT "EMB. FECHADA",
                                       INPUT bf-tt.it-codigo,
                                       INPUT bf-tt.lote,
                                       INPUT bf-tt.desc-item,
                                       INPUT bf-tt.un,
                                       INPUT iContador,
                                       INPUT bf-tt.capacidade,
                                       INPUT cConcluido).
        END.

        /* componente coberto so por embalagem fechada: nada vai a balanca */
        IF bf-tt.qt-pesar <= 0 THEN
            NEXT.

        /* ---- abaixo do minimo da balanca: separado a mao, sem pesagem ---- */
        IF bf-tt.qt-pesar < dPesoMinBalanca THEN DO:

            RUN pi-cria-linha-pesagem (INPUT "PESAGEM",
                                       INPUT bf-tt.it-codigo,
                                       INPUT bf-tt.lote,
                                       INPUT bf-tt.desc-item,
                                       INPUT bf-tt.un,
                                       INPUT 1,
                                       INPUT bf-tt.qt-pesar,
                                       INPUT cConcluido).
            NEXT.
        END.

        /* ---- volumes que vao a balanca ---- */
        ASSIGN
            iVolumesCheios = TRUNCATE(bf-tt.qt-pesar / dPesoMaxVolume, 0)
            dResto         = bf-tt.qt-pesar - (iVolumesCheios * dPesoMaxVolume)
            dUltimoCheio   = dPesoMaxVolume.

        /* sobra impesavel eh absorvida pelo ultimo volume cheio */
        IF dResto > 0 AND dResto < dPesoMinBalanca AND iVolumesCheios > 0 THEN
            ASSIGN
                dUltimoCheio = dPesoMaxVolume + dResto
                dResto       = 0.

        DO iContador = 1 TO iVolumesCheios:

            ASSIGN dQtVolume = (IF iContador = iVolumesCheios
                                THEN dUltimoCheio
                                ELSE dPesoMaxVolume).

            RUN pi-cria-linha-pesagem (INPUT "PESAGEM",
                                       INPUT bf-tt.it-codigo,
                                       INPUT bf-tt.lote,
                                       INPUT bf-tt.desc-item,
                                       INPUT bf-tt.un,
                                       INPUT iContador,
                                       INPUT dQtVolume,
                                       INPUT "PENDENTE").
        END.

        IF dResto > 0 THEN
            RUN pi-cria-linha-pesagem (INPUT "PESAGEM",
                                       INPUT bf-tt.it-codigo,
                                       INPUT bf-tt.lote,
                                       INPUT bf-tt.desc-item,
                                       INPUT bf-tt.un,
                                       INPUT iVolumesCheios + 1,
                                       INPUT dResto,
                                       INPUT "PENDENTE").
    END.


    /* capacidade errada na escq0004 nao pode virar tela travada em silencio */
    IF cAvisoParam <> "" THEN
        MESSAGE "Capacidade de embalagem suspeita, cadastrada na escq0004:"
                + CHR(10) + cAvisoParam + CHR(10)
                + "A lista foi cortada em "
                + TRIM(STRING(iMaxEmbalagens, ">>>,>>9"))
                + " linhas por item. Confira o cadastro."
            VIEW-AS ALERT-BOX WARNING BUTTONS OK.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-op-esta-finalizada wWin 
PROCEDURE pi-op-esta-finalizada :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-pos-cursor-brPesagem wWin 
PROCEDURE pi-pos-cursor-brPesagem :
/*------------------------------------------------------------------------------
  PROCEDURE pi-pos-cursor-brPesagem
  Purpose:     Posiciona a linha corrente do brPesagem no proximo volume
               pendente do item em cItCodigo. Nao havendo, vai para a ultima
               linha do browse.
  Parameters:  <none>
  Notes:       Usa buffer proprio (bf-vol) - mexer no buffer default
               dessincronizaria a linha destacada do browse.
------------------------------------------------------------------------------*/
    DEFINE VARIABLE rLinha AS ROWID NO-UNDO.

    DEFINE BUFFER bf-vol FOR tt-pesagem-item.

    IF cItCodigo <> "" THEN DO:

        FIND FIRST bf-vol
            WHERE bf-vol.it-codigo = cItCodigo
              AND bf-vol.tipo      = "PESAGEM"
              AND bf-vol.situacao  = "PENDENTE"
            NO-ERROR.

        IF AVAILABLE bf-vol THEN
            ASSIGN rLinha = ROWID(bf-vol).
    END.

    IF rLinha = ? THEN DO:

        FIND LAST bf-vol NO-ERROR.

        IF AVAILABLE bf-vol THEN
            ASSIGN rLinha = ROWID(bf-vol).
    END.

    IF rLinha = ? THEN
        RETURN.

    REPOSITION brPesagem TO ROWID rLinha NO-ERROR.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-pos-cursor-itensReq wWin 
PROCEDURE pi-pos-cursor-itensReq :
/*------------------------------------------------------------------------------
  Purpose:     Posiciona a linha corrente do browse br-itensReq no item que
               esta em cItCodigo. Nao encontrando o item (ou com cItCodigo
               vazio), posiciona na ultima linha do browse.
  Parameters:  <none>
  Notes:       Usa buffer proprio (bf-tt) para localizar o registro. Mexer no
               buffer default tt-req-ord aqui dessincronizaria o browse, que
               usa esse mesmo buffer.
------------------------------------------------------------------------------*/
    DEFINE VARIABLE rLinha AS ROWID NO-UNDO.

    DEFINE BUFFER bf-tt FOR tt-req-ord.

    /* Procura o item devolvido */
    IF cItCodigo <> "" THEN DO:
        FIND FIRST bf-tt
            WHERE bf-tt.it-codigo = cItCodigo
            NO-ERROR.

        IF AVAILABLE bf-tt THEN
            ASSIGN rLinha = ROWID(bf-tt).
    END.

    /* Nao achou: cai na ultima linha */
    IF rLinha = ? THEN DO:
        FIND LAST bf-tt NO-ERROR.

        IF AVAILABLE bf-tt THEN
            ASSIGN rLinha = ROWID(bf-tt).
    END.

    /* Browse vazio: nada a fazer */
    IF rLinha = ? THEN
        RETURN.

    REPOSITION br-itensReq TO ROWID rLinha NO-ERROR.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-prepara-componentes wWin 
PROCEDURE pi-prepara-componentes :
/*------------------------------------------------------------------------------
  pi-prepara-componentes
  Purpose:     Verifica e cria os registros de es_pesagem_componente
               para os itens da OP.
  Parameters:  piOrdem (INPUT) - numero da ordem de producao
------------------------------------------------------------------------------*/

    DEFINE INPUT PARAMETER piOrdem AS INTEGER NO-UNDO.

    DEFINE BUFFER bf-ord   FOR ord-prod.
    DEFINE BUFFER bf-req   FOR req-ord.
    DEFINE BUFFER bf-comp  FOR es_pesagem_componente.
    DEFINE BUFFER bf-param FOR es_pesagem_param.

    DEFINE VARIABLE iQtEmbalagens AS INTEGER NO-UNDO.
    DEFINE VARIABLE dQtPesar      AS DECIMAL NO-UNDO.

    /*=============================================================
        BUSCA ORDEM DE PRODUCAO
    ===============================================================*/

    FIND FIRST bf-ord NO-LOCK
        WHERE bf-ord.nr-ord-produ = piOrdem
        NO-ERROR.

    IF NOT AVAILABLE bf-ord THEN
        RETURN.

    /*=============================================================
        PERCORRE OS ITENS REQUISITADOS DA OP
    ===============================================================*/

    FOR EACH bf-req NO-LOCK
        WHERE bf-req.nr-ord-produ = piOrdem:

        /*---------------------------------------------------------
            Verifica se o componente ja existe
        ---------------------------------------------------------*/

        FIND FIRST bf-comp NO-LOCK
            WHERE bf-comp.nr_ordem = piOrdem
              AND bf-comp.item     = bf-req.it-codigo
              AND bf-comp.lote     = bf-req.lote-serie
            NO-ERROR.

        IF AVAILABLE bf-comp THEN
            NEXT.

        /*---------------------------------------------------------
            Busca capacidade da embalagem
        ---------------------------------------------------------*/

        FIND FIRST bf-param NO-LOCK
            WHERE bf-param.item_pai   = bf-ord.it-codigo
              AND bf-param.item_filho = bf-req.it-codigo
            NO-ERROR.

        /*---------------------------------------------------------
            Calcula embalagens fechadas e quantidade a pesar
        ---------------------------------------------------------*/

        IF AVAILABLE bf-param
           AND bf-param.capacidade_embalagem > 0 THEN DO:

            ASSIGN
                iQtEmbalagens = TRUNCATE(
                                    bf-req.qtd-requisitd-lote /
                                    bf-param.capacidade_embalagem,
                                    0
                                )

                dQtPesar = bf-req.qtd-requisitd-lote -
                           (
                               iQtEmbalagens *
                               bf-param.capacidade_embalagem
                           ).

        END.
        ELSE DO:

            ASSIGN
                iQtEmbalagens = 0
                dQtPesar      = bf-req.qtd-requisitd-lote.

        END.

        /*---------------------------------------------------------
            Cria componente
        ---------------------------------------------------------*/

        CREATE bf-comp.

        ASSIGN
            bf-comp.nr_ordem                     = piOrdem
            bf-comp.item                         = bf-req.it-codigo
            bf-comp.lote                         = bf-req.lote-serie
            bf-comp.qt_requisitada               = bf-req.qtd-requisitd-lote
            bf-comp.capacidade_embalagem         = (IF AVAILABLE bf-param
                                                    THEN bf-param.capacidade_embalagem
                                                    ELSE 0)
            bf-comp.qt_pesada_balanca            = 0
            bf-comp.qt_embalagens_fechadas       = iQtEmbalagens
            bf-comp.qt_volumes                   = 0
            bf-comp.qt_desvio_requisitada_pesada = 0
            bf-comp.pc_desvio                    = 0
            bf-comp.qt_reimpressoes              = 0
            bf-comp.total_tentativas             = 0
            bf-comp.situacao                     = (IF dQtPesar < dPesoMinBalanca
                                                    THEN 3
                                                    ELSE 2).

    END.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-prepara-itens-op wWin 
PROCEDURE pi-prepara-itens-op :
/*------------------------------------------------------------------------------
  pi-prepara-itens-op
  Purpose:     Monta a tt-req-ord com os itens requisitados da OP
               e atualiza o browse br-itensReq.
  Parameters:  piOrdem (INPUT) - numero da ordem de producao
------------------------------------------------------------------------------*/

    DEFINE INPUT PARAMETER piOrdem AS INTEGER NO-UNDO.

    DEFINE VARIABLE cSituacaoDesc AS CHARACTER NO-UNDO.

    DEFINE BUFFER bf-ord    FOR ord-prod.
    DEFINE BUFFER bf-req    FOR req-ord.
    DEFINE BUFFER bf-item   FOR item.
    DEFINE BUFFER bf-estrut FOR estrutura.
    DEFINE BUFFER bf-saldo  FOR saldo-estoq.
    DEFINE BUFFER bf-param  FOR es_pesagem_param.
    DEFINE BUFFER bf-comp   FOR es_pesagem_componente.

    /* quem monta eh quem limpa: sem isso, chamar a procedure uma segunda vez
       (ao fechar a OP) duplicaria todas as linhas do browse de cima */
    EMPTY TEMP-TABLE tt-req-ord.

    /*=============================================================
        LOCALIZA A ORDEM DE PRODUCAO
    ===============================================================*/

    FIND FIRST bf-ord NO-LOCK
        WHERE bf-ord.nr-ord-produ = piOrdem
        NO-ERROR.

    IF NOT AVAILABLE bf-ord THEN
        RETURN.

    /*=============================================================
        MONTA OS ITENS REQUISITADOS DA ORDEM
    ===============================================================*/

    FOR EACH bf-req NO-LOCK
        WHERE bf-req.nr-ord-produ = piOrdem:

        /*---------------------------------------------------------
            DESCRICAO E UNIDADE
        ---------------------------------------------------------*/

        FIND FIRST bf-item NO-LOCK
            WHERE bf-item.it-codigo = bf-req.it-codigo
            NO-ERROR.

        /*---------------------------------------------------------
            QUANTIDADE DA RECEITA
        ---------------------------------------------------------*/

        FIND FIRST bf-estrut NO-LOCK
            WHERE bf-estrut.it-codigo = bf-ord.it-codigo
              AND bf-estrut.es-codigo = bf-req.it-codigo
            NO-ERROR.

        /*---------------------------------------------------------
            VALIDADE DO LOTE
        ---------------------------------------------------------*/

        FIND FIRST bf-saldo NO-LOCK
            WHERE bf-saldo.num-id-saldo-estoq =
                  bf-req.num-id-saldo-estoq
            NO-ERROR.

        /*---------------------------------------------------------
            CAPACIDADE DA EMBALAGEM
        ---------------------------------------------------------*/

        FIND FIRST bf-param NO-LOCK
            WHERE bf-param.item_pai   = bf-ord.it-codigo
              AND bf-param.item_filho = bf-req.it-codigo
            NO-ERROR.

        /*---------------------------------------------------------
            SITUACAO JA GRAVADA PARA ESTE ITEM
        ---------------------------------------------------------*/

        FIND FIRST bf-comp NO-LOCK
            WHERE bf-comp.nr_ordem = piOrdem
              AND bf-comp.item     = bf-req.it-codigo
              AND bf-comp.lote     = bf-req.lote-serie
            NO-ERROR.

        IF AVAILABLE bf-comp THEN
            RUN pi-verificar-situacao (
                INPUT  bf-comp.situacao,
                OUTPUT cSituacaoDesc
            ).
        ELSE
            ASSIGN cSituacaoDesc = "EM ANDAMENTO".

        /*=========================================================
            CRIA REGISTRO NA TT-REQ-ORD
        ===========================================================*/

        CREATE tt-req-ord.

        ASSIGN
            tt-req-ord.it-codigo      = bf-req.it-codigo
            tt-req-ord.lote           = bf-req.lote-serie
            tt-req-ord.qt-requisitada = bf-req.qtd-requisitd-lote
            tt-req-ord.situacao       = cSituacaoDesc

            tt-req-ord.capacidade     =
                (IF AVAILABLE bf-param
                 THEN bf-param.capacidade_embalagem
                 ELSE 0)

            tt-req-ord.un             =
                (IF AVAILABLE bf-item
                 THEN bf-item.un
                 ELSE "")

            tt-req-ord.desc-item      =
                (IF AVAILABLE bf-item
                 THEN bf-item.desc-item
                 ELSE "")

            tt-req-ord.valid-lote     =
                (IF AVAILABLE bf-saldo
                 THEN bf-saldo.dt-vali-lote
                 ELSE ?)

            tt-req-ord.qt-receita     =
                (IF AVAILABLE bf-estrut
                 THEN bf-estrut.quant-usada * bf-ord.qt-ordem
                 ELSE 0)

            tt-req-ord.qt-embalagens  =
                (IF AVAILABLE bf-param
                    AND bf-param.capacidade_embalagem > 0
                 THEN
                    TRUNCATE(
                        bf-req.qtd-requisitd-lote /
                        bf-param.capacidade_embalagem,
                        0
                    )
                 ELSE 0)

            tt-req-ord.qt-pesar       =
                (IF AVAILABLE bf-param
                    AND bf-param.capacidade_embalagem > 0
                 THEN
                    bf-req.qtd-requisitd-lote -
                    (
                        TRUNCATE(
                            bf-req.qtd-requisitd-lote /
                            bf-param.capacidade_embalagem,
                            0
                        ) * bf-param.capacidade_embalagem
                    )
                 ELSE
                    bf-req.qtd-requisitd-lote).

    END.

    /*=============================================================
        ATUALIZA O BROWSE
    ===============================================================*/

    {&OPEN-QUERY-br-itensReq}

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-processa-pesagem wWin 
PROCEDURE pi-processa-pesagem :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-projeta-desvio-componente wWin 
PROCEDURE pi-projeta-desvio-componente :
/*------------------------------------------------------------------------------
  PROCEDURE pi-projeta-desvio-componente
  Purpose:     Camada 2 (componente). Projeta o desvio acumulado do componente
               e devolve o aviso a ser mostrado ao operador.
  Parameters:  piOrdem    (INPUT)  - numero da ordem de producao
               prVolume   (INPUT)  - ROWID do volume recem confirmado
               pcAviso    (OUTPUT) - texto do aviso, "" quando esta tudo certo
               plEstourou (OUTPUT) - TRUE quando passou do teto (irrecuperavel)
  Notes:       Peso so acumula, nunca diminui. Por isso passar do limite
               superior nao tem conserto, enquanto ficar abaixo do inferior eh
               recuperavel enquanto houver volume restante.
               Tolerancia zero eh tratada como "nao cadastrada".
               Usa item + lote da linha do volume - cItCodigo sozinho nao
               identifica o componente quando o item vem em dois lotes.
------------------------------------------------------------------------------*/
    DEFINE INPUT  PARAMETER piOrdem    AS INTEGER   NO-UNDO.
    DEFINE INPUT  PARAMETER prVolume   AS ROWID     NO-UNDO.
    DEFINE OUTPUT PARAMETER pcAviso    AS CHARACTER NO-UNDO.
    DEFINE OUTPUT PARAMETER plEstourou AS LOGICAL   NO-UNDO.

    DEFINE VARIABLE dTolerancia AS DECIMAL NO-UNDO.
    DEFINE VARIABLE dEntregue   AS DECIMAL NO-UNDO.
    DEFINE VARIABLE dRestante   AS DECIMAL NO-UNDO.
    DEFINE VARIABLE dLimInf     AS DECIMAL NO-UNDO.
    DEFINE VARIABLE dLimSup     AS DECIMAL NO-UNDO.

    DEFINE BUFFER bf-vol   FOR tt-pesagem-item.
    DEFINE BUFFER bf-pend  FOR tt-pesagem-item.
    DEFINE BUFFER bf-ord   FOR ord-prod.
    DEFINE BUFFER bf-comp  FOR es_pesagem_componente.
    DEFINE BUFFER bf-param FOR es_pesagem_param.

    FIND bf-vol WHERE ROWID(bf-vol) = prVolume NO-ERROR.

    IF NOT AVAILABLE bf-vol THEN
        RETURN.

    FIND FIRST bf-ord NO-LOCK
        WHERE bf-ord.nr-ord-produ = piOrdem
        NO-ERROR.

    FIND FIRST bf-comp NO-LOCK
        WHERE bf-comp.nr_ordem = piOrdem
          AND bf-comp.item     = bf-vol.it-codigo
          AND bf-comp.lote     = bf-vol.lote
        NO-ERROR.

    IF NOT AVAILABLE bf-ord OR NOT AVAILABLE bf-comp THEN
        RETURN.

    FIND FIRST bf-param NO-LOCK
        WHERE bf-param.item_pai   = bf-ord.it-codigo
          AND bf-param.item_filho = bf-vol.it-codigo
        NO-ERROR.

    ASSIGN dTolerancia = (IF AVAILABLE bf-param
                          THEN bf-param.tolerancia
                          ELSE 0).

    IF dTolerancia <= 0 OR bf-comp.qt_requisitada <= 0 THEN
        RETURN.

    ASSIGN
        dEntregue = (bf-comp.qt_embalagens_fechadas * bf-comp.capacidade_embalagem)
                    + bf-comp.qt_pesada_balanca
        dLimInf   = bf-comp.qt_requisitada * (1 - (dTolerancia / 100))
        dLimSup   = bf-comp.qt_requisitada * (1 + (dTolerancia / 100)).

    /* quanto deste componente ainda esta planejado e nao pesado */
    FOR EACH bf-pend NO-LOCK
        WHERE bf-pend.it-codigo = bf-vol.it-codigo
          AND bf-pend.lote      = bf-vol.lote
          AND bf-pend.tipo      = "PESAGEM"
          AND bf-pend.situacao  = "PENDENTE":
        ASSIGN dRestante = dRestante + bf-pend.qt-pesar.
    END.

    /* passou do teto: nenhum volume seguinte corrige */
    IF dEntregue > dLimSup THEN DO:
        ASSIGN
            plEstourou = TRUE
            pcAviso    = "PARE. O componente " + TRIM(bf-vol.it-codigo)
                       + " passou do limite."                                    + CHR(10)
                       + "Entregue: " + TRIM(STRING(dEntregue, "->>>,>>9.9999")) + CHR(10)
                       + "Maximo..: " + TRIM(STRING(dLimSup,   "->>>,>>9.9999")) + CHR(10)
                       + "Peso so acumula - os proximos volumes nao corrigem isso.".
        RETURN.
    END.

    /* ainda ha volume por pesar */
    IF dRestante > 0 THEN DO:

        IF dEntregue + dRestante < dLimInf THEN
            ASSIGN pcAviso = "Atencao: o que resta planejado ("
                           + TRIM(STRING(dRestante, "->>>,>>9.9999"))
                           + ") nao alcanca o minimo do componente."             + CHR(10)
                           + "Faltam pelo menos "
                           + TRIM(STRING(dLimInf - dEntregue, "->>>,>>9.9999")) + ".".
        RETURN.
    END.

    /* ultimo volume fechado: verificacao definitiva */
    IF dEntregue < dLimInf THEN
        ASSIGN pcAviso = "Componente " + TRIM(bf-vol.it-codigo)
                       + " fechou abaixo da tolerancia."                         + CHR(10)
                       + "Entregue: " + TRIM(STRING(dEntregue, "->>>,>>9.9999")) + CHR(10)
                       + "Minimo..: " + TRIM(STRING(dLimInf,   "->>>,>>9.9999")).

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-valida-inicio-pesagem wWin 
PROCEDURE pi-valida-inicio-pesagem :
DEFINE INPUT  PARAMETER piOrdem AS INTEGER NO-UNDO.
    DEFINE OUTPUT PARAMETER plOk    AS LOGICAL NO-UNDO.

    DEFINE VARIABLE cSituacaoDesc AS CHARACTER NO-UNDO.

    DEFINE BUFFER bf-ord     FOR ord-prod.
    DEFINE BUFFER bf-mistura FOR es_pesagem_mistura. 
    
    ASSIGN plOk = FALSE.

    IF cOrdemProducao = "" THEN DO:
        MESSAGE "Nenhuma OP disponivel."
            VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.
        RETURN.
    END.

    FIND FIRST bf-ord NO-LOCK
        WHERE bf-ord.nr-ord-produ = piOrdem
        NO-ERROR.

    IF NOT AVAILABLE bf-ord THEN DO:
        MESSAGE "OP nao encontrada."
            VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.
        RETURN.
    END.

    FIND FIRST bf-mistura NO-LOCK
        WHERE bf-mistura.nr_ordem = piOrdem
        NO-ERROR.

    IF NOT AVAILABLE bf-mistura THEN DO:
        MESSAGE "Nao encontrou a PESAGEM MISTURA."
            VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.
        RETURN.
    END.

    IF bf-mistura.situacao = 0 THEN DO:
        MESSAGE "Ops! Situacao nao identificada. Verifique a OP."
            VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.
        RETURN.
    END.

    RUN pi-verificar-situacao (INPUT  bf-mistura.situacao,
                               OUTPUT cSituacaoDesc).

    // Nao permite imprimir se nao tiver concluido
    //btImprimir:SENSITIVE IN FRAME fMain = FALSE.                           
                               
    IF cSituacaoDesc = "CONCLUIDO" THEN DO:
        MESSAGE "A OP " + cOrdemProducao + " ja esta CONCLUIDA."
            VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.
            
        /* Permite imprimir */
        //btImprimir:SENSITIVE IN FRAME fMain = TRUE.
        
        /* Carrega browser 'de baixo' */
        
        RETURN.
    END.

    ASSIGN plOk = TRUE.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-valida-op wWin 
PROCEDURE pi-valida-op :
/*------------------------------------------------------------------------------
  Purpose:     Verifica se a OP existe e se tem itens requisitados.
  Parameters:  piOrdem (INPUT)  - numero da ordem de producao
               plOk    (OUTPUT) - TRUE quando a OP esta apta a ser carregada
  Notes:       Emite a mensagem e chama pi-limpa-tela nos casos de recusa.
------------------------------------------------------------------------------*/
    DEFINE INPUT  PARAMETER piOrdem AS INTEGER NO-UNDO.
    DEFINE OUTPUT PARAMETER plOk    AS LOGICAL NO-UNDO.

    DEFINE BUFFER bf-ord FOR ord-prod.
    DEFINE BUFFER bf-req FOR req-ord.
    
    ASSIGN plOk = FALSE.

    FIND FIRST bf-ord NO-LOCK
        WHERE bf-ord.nr-ord-produ = piOrdem
        NO-ERROR.

    IF NOT AVAILABLE bf-ord THEN DO:
        MESSAGE "OP nao encontrada!" STRING(piOrdem)
            VIEW-AS ALERT-BOX ERROR.
        RUN pi-limpa-tela.
        RETURN.
    END.

    FIND FIRST bf-req NO-LOCK
        WHERE bf-req.nr-ord-produ = piOrdem
        NO-ERROR.

    IF NOT AVAILABLE bf-req THEN DO:
        MESSAGE "Nao existem registros na req-ord para a OP" STRING(piOrdem)
            VIEW-AS ALERT-BOX INFORMATION.
        RUN pi-limpa-tela.
        RETURN.
    END.

    ASSIGN plOk = TRUE.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-valida-peso-volume wWin 
PROCEDURE pi-valida-peso-volume :
/*------------------------------------------------------------------------------
  PROCEDURE pi-valida-peso-volume
  Purpose:     Camada 1 (tela) mais o limite fisico da balanca. Valida o peso
               lido contra o alvo daquele volume.
  Parameters:  prVolume    (INPUT)  - ROWID do volume na tt-pesagem-item
               pdPeso      (INPUT)  - peso informado
               plOk        (OUTPUT) - TRUE quando o peso pode ser gravado
               piResultado (OUTPUT) - codigo do desfecho, gravado no log
  Notes:       Codigos de resultado:
                 1 - OK
                 2 - peso invalido (zero ou nao numerico)
                 3 - acima do limite da balanca
                 4 - fora da tolerancia de tela
                 5 - volume invalido
               A tolerancia de tela eh percentual sobre o alvo do volume, e
               vale para os dois lados (usa ABSOLUTE).
------------------------------------------------------------------------------*/
    DEFINE INPUT  PARAMETER prVolume    AS ROWID   NO-UNDO.
    DEFINE INPUT  PARAMETER pdPeso      AS DECIMAL NO-UNDO.
    DEFINE OUTPUT PARAMETER plOk        AS LOGICAL NO-UNDO.
    DEFINE OUTPUT PARAMETER piResultado AS INTEGER NO-UNDO.

    DEFINE VARIABLE dDesvio AS DECIMAL NO-UNDO.

    DEFINE BUFFER bf-vol FOR tt-pesagem-item.

    FIND bf-vol WHERE ROWID(bf-vol) = prVolume NO-ERROR.

    IF NOT AVAILABLE bf-vol OR bf-vol.qt-pesar <= 0 THEN DO:
        ASSIGN piResultado = 5.  /* volume invalido */
        RETURN.
    END.

    IF pdPeso <= 0 THEN DO:
        ASSIGN piResultado = 2.  /* peso invalido */
        MESSAGE "Informe um peso maior que zero."
            VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.
        RETURN.
    END.

    IF pdPeso > dPesoMaxBalanca THEN DO:
        ASSIGN piResultado = 3.  /* acima da balanca */
        MESSAGE "Peso acima do limite da balanca ("
                + TRIM(STRING(dPesoMaxBalanca, "->>9.99")) + " KG)."
            VIEW-AS ALERT-BOX ERROR BUTTONS OK.
        RETURN.
    END.

    ASSIGN dDesvio = ABSOLUTE((bf-vol.qt-pesar - pdPeso)
                              / bf-vol.qt-pesar * 100).
    
    
    IF dDesvio > dToleranciaPesagem THEN DO:
        ASSIGN piResultado = 4. /* fora da tolerancia */

        MESSAGE
            "PESO FORA DA TOLER¶NCIA" SKIP(2)
            "Alvo do volume: " STRING(bf-vol.qt-pesar, "->>>,>>9.9999") SKIP
            "Foi pesado.......:  " STRING(pdPeso,          "->>>,>>9.9999") SKIP
            "Desvio...............:      " STRING(dDesvio,         "->>9.99") "%" SKIP
            "Tolerƒncia.........:     " STRING(dToleranciaPesagem, "->>9.99") "%"
            VIEW-AS ALERT-BOX ERROR
            BUTTONS OK.

        RETURN.
    END.

    ASSIGN
        plOk        = TRUE
        piResultado = 1.  /* OK */

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-verificar-item-nao-concluido wWin 
PROCEDURE pi-verificar-item-nao-concluido :
/*------------------------------------------------------------------------------
  Purpose:     Percorre os componentes da OP corrente (es_pesagem_componente) e
               devolve o primeiro item, na ordem de sequencia, cuja situacao
               seja 2 (em andamento).
  Parameters:  pcItem      (OUTPUT) - it-codigo encontrado ("" se nao houver)
               pcDescItem  (OUTPUT) - descricao do item, em maiusculas
               piSequencia (OUTPUT) - sequencia do componente (0 se nao houver)
  Notes:       Usa buffers proprios (bf-) para nao mexer nos buffers default,
               que sao usados por outras procedures do programa.
------------------------------------------------------------------------------*/

    DEFINE OUTPUT PARAMETER pcItem      AS CHARACTER NO-UNDO.
    DEFINE OUTPUT PARAMETER pcDescItem  AS CHARACTER NO-UNDO.
    DEFINE OUTPUT PARAMETER piSequencia AS INTEGER   NO-UNDO.
    
    DEFINE BUFFER bf-comp FOR es_pesagem_componente.
    DEFINE BUFFER bf-item FOR item.
    
    ASSIGN
        pcItem      = ""
        pcDescItem  = ""
        piSequencia = 0.
    
    FOR EACH bf-comp NO-LOCK
        WHERE bf-comp.nr_ordem = INTEGER(cOrdemProducao)
          AND bf-comp.situacao = 2 /* EM ATENDIMENTO */
        BY bf-comp.sequencia:
   
                ASSIGN
                    pcItem      = bf-comp.item
                    piSequencia = bf-comp.sequencia.
                    
                FIND FIRST bf-item NO-LOCK
                    WHERE bf-item.it-codigo = bf-comp.ITEM
                    NO-ERROR.
                IF AVAILABLE bf-item THEN
                    ASSIGN pcDescItem = CAPS(bf-item.desc-item).
                    
                LEAVE.
                
    END.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-verificar-situacao wWin 
PROCEDURE pi-verificar-situacao :
/*------------------------------------------------------------------------------
  Purpose:     Traduz o c¢digo num‚rico gravado em es_pesagem_mistura.situacao
               para o texto exibido em fi-situacao na tela.
  Parameters:  piSituacao (INPUT)  - c¢digo num‚rico da situa‡Æo
                                      (1 = Pendente, 2 = Em andamento,
                                      3 = Conclu¡do; qualquer outro valor
                                      retorna "NÆo identificado")
               pcSituacao (OUTPUT) - texto correspondente ao c¢digo recebido
------------------------------------------------------------------------------*/
    DEFINE INPUT  PARAMETER piSituacao AS INTEGER   NO-UNDO.
    DEFINE OUTPUT PARAMETER pcSituacao AS CHARACTER NO-UNDO.

    CASE piSituacao:
        WHEN 1 THEN
            pcSituacao = "PENDENTE".
        WHEN 2 THEN
            pcSituacao = "EM ANDAMENTO".
        WHEN 3 THEN
            pcSituacao = "CONCLUIDO".
        OTHERWISE
            pcSituacao = "NAO IDENTIFICADO".
    END CASE.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-volume-corrente wWin 
PROCEDURE pi-volume-corrente :
/*------------------------------------------------------------------------------
  PROCEDURE pi-volume-corrente
  Purpose:     Devolve o ROWID do proximo volume pendente do item corrente.
  Parameters:  prVolume (OUTPUT) - ROWID na tt-pesagem-item, ? se nao houver
  Notes:       Filtra tipo = "PESAGEM" - linha de EMB. FECHADA nao vai a balanca, e
               linha "NAO PESAR" (abaixo de 5 g) tambem fica de fora porque so
               "PENDENTE" eh considerado.
------------------------------------------------------------------------------*/
    DEFINE OUTPUT PARAMETER prVolume AS ROWID NO-UNDO.

    DEFINE BUFFER bf-vol FOR tt-pesagem-item.

    FIND FIRST bf-vol
        WHERE bf-vol.it-codigo = cItCodigo
          AND bf-vol.tipo      = "PESAGEM"
          AND bf-vol.situacao  = "PENDENTE"
        NO-ERROR.

    IF AVAILABLE bf-vol THEN
        ASSIGN prVolume = ROWID(bf-vol).

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


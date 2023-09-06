/* change comments */
cas sascas1; /**/
libname mycas cas caslib = "casuser"; /**/

data mycas.instdata1; /**/
   length
      instid   varchar(*)
      insttype varchar(*)
      clvar_1  varchar(*)
      clvar_2  varchar(*)
      ;
   instid = "InstId_1"; insttype="Inst1"; clvar_1="clvar_1_0"; clvar_2="clvar_2_0"; numval=1; holding=1; output;
   instid = "InstId_2"; insttype="Inst1"; clvar_1="clvar_1_1"; clvar_2="clvar_2_1"; numval=1; holding=1; output;
   instid = "InstId_3"; insttype="Inst1"; clvar_1="clvar_1_0"; clvar_2="clvar_2_2"; numval=1; holding=1; output;
run;
quit;

/* proc cas; */
/* table.promote / caslib="casuser" name="instdata1" targetcaslib="casuser"; */
/* run;quit; */

data mycas.mktdata; /**/
   rf1 = 1;
   rf2 = 2;
   rf3 = 3;
   output;
run;
quit;

data mycas.scendata; /**/
   length 
      SCENARIO_NAME  varchar(*)
      _NAME_         varchar(*)
      _TYPE_         varchar(*)
      _CHAR_VALUE_   varchar(*)
      BASELINE       varchar(*)         
      Label          varchar(*)         
      LongLabel      varchar(*)         
      ;
   retain BASELINE "";
   retain Label "";
   retain LongLabel "";
   retain _CHAR_VALUE_ "";
   _TYPE_ = "VALUE";
   INTERVAL = "DAY";
   SCENARIO_NAME="Scen1"; _NAME_="rf1"; HORIZON=1; _VALUE_=1.011; output;
   SCENARIO_NAME="Scen1"; _NAME_="rf1"; HORIZON=2; _VALUE_=1.012; output;
   SCENARIO_NAME="Scen2"; _NAME_="rf1"; HORIZON=1; _VALUE_=1.021; output;
   SCENARIO_NAME="Scen2"; _NAME_="rf1"; HORIZON=2; _VALUE_=1.022; output;
   SCENARIO_NAME="Scen1"; _NAME_="rf2"; HORIZON=1; _VALUE_=2.011; output;
   SCENARIO_NAME="Scen1"; _NAME_="rf2"; HORIZON=2; _VALUE_=2.012; output;
   SCENARIO_NAME="Scen2"; _NAME_="rf2"; HORIZON=1; _VALUE_=2.021; output;
   SCENARIO_NAME="Scen2"; _NAME_="rf2"; HORIZON=2; _VALUE_=2.022; output;
   SCENARIO_NAME="Scen1"; _NAME_="rf3"; HORIZON=1; _VALUE_=3.011; output;
   SCENARIO_NAME="Scen1"; _NAME_="rf3"; HORIZON=2; _VALUE_=3.012; output;
   SCENARIO_NAME="Scen2"; _NAME_="rf3"; HORIZON=1; _VALUE_=3.021; output;
   SCENARIO_NAME="Scen2"; _NAME_="rf3"; HORIZON=2; _VALUE_=3.022; output;
run;
quit;

data mycas.envIn;
   length 
      CATEGORY    varchar(*)
      SUBCATEGORY varchar(*)
      NAME        varchar(*)
      ATTRIBUTES  varchar(*)
      ;
   /* EVAL_TYPE - INSTRUMENT */
   CATEGORY = "EVAL_TYPE"; SUBCATEGORY = "INSTRUMENT";
   ATTRIBUTES = '{"evaluationType":{"method":"PRICE1"}}';
   NAME = "INST1"; output;

   /* VARIABLE - INSTRUMENT (class) */
   CATEGORY = "VARIABLE"; SUBCATEGORY = "INSTRUMENT";
   ATTRIBUTES = '{"varAttr":{"role":"CLASS"}}';
   NAME = "clvar_1"; output;
   NAME = "clvar_2"; output;

   /* VARIABLE - PRICE */
   CATEGORY = "VARIABLE"; SUBCATEGORY = "PRICE";
   ATTRIBUTES = '{"varAttr":{"role":"COMPUTED"}}';
   NAME = "ov1"; output;
   NAME = "ov2"; output;
   
   ATTRIBUTES = '{"varAttr":{"label":"Value of Instrument Returned","role":"COMPUTED"}}';
   NAME = "Value";  output;

   ATTRIBUTES = '{"varAttr":{"role":"COMPUTED"},"outOpts":{"baseVar":"Value","subtractMtm":true,"flipVaR":true}}';
   NAME = "PL"; output;
   
   /* PROJECT */
   CATEGORY = "PROJECT"; SUBCATEGORY = "";
   ATTRIBUTES = '{"projAttr":{"name":"ScenPerf","defaultAsOfDate":"2020-05-01"}}';
   NAME = "ScenPerf"; output;
run;
quit;

proc cas;
   source methCode;
      method Price1 kind=price; /**/
         _value_ = rf1 * numval; /**/
         ov1 = rf2 + 1;
         ov2 = rf3 + 2;
      endmethod;
   endsource;
   action riskMethods.add / 
      envTable = { caslib="casuser" name="envIn" } /**/
      envOut = { table={caslib="casuser" name="envMethOut" } } /**/
      methodTable= {caslib="casuser" name="methods1" replace=true} /**/
      methodCode= methCode
   ;
   run;
quit;

proc cas;
   action risksim.genScenarioStates /
      envTable = {caslib = "casuser", name = "envMethOut"}
      envOut = {table={caslib="casuser" name="envScenOut"}}
      currMktTable = {caslib = "casuser", name = "mktdata"}
      scenarios       = {
         scenariosTable = { 
            caslib = "casuser", name = "scenData"
         } 
         asOfDate = "10MAY2021"
         scenStatesOut= {
            caslib = "casuser", name = "scen_Out", replication=0
         }                     
      }
   ;
   run;
quit;

proc cas;
   parms = { /**/
      envTable =        {caslib="casuser", name="envScenOut"}
      instrumentTable = {caslib="casuser", name="instdata1"}
      envOut =          {table={caslib="casuser" name="env1"}}
      valuesOut =       {casLib="casuser" name="env1_values"}
   };
   action riskrun.evaluatePortfolio / parms;
   run;
quit;

proc cas;
   parms = {
      envTable = { caslib = "casuser", name = "env1" } 
      type = "AGGREGATE"
      outputs  = {
        { table = { caslib = "casuser", name = "env1_vals" }, 
          type = "VALUES" }
      }
      requests = { {levels = {"instid"}} }
   };
   action riskresults.query / parms;
   run;
quit;
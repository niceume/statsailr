# StatSailr

StatSailr provides a platform for users to focus on statistics. The backend statistics engine is [R](https://www.r-project.org/), so the results are reliable. The SataSailr script consists of three major blocks, TOPLEVEL, DATA, and PROC. Each block has its way of writing instructions, which works as an intuitive interface for R.


## Overview

StatSailr is a Ruby program that enables users to manipulate data and to apply statistical procedures in an intuiitive way. StatSailr converts StatSailr script into R's internal representation, and executes it. The SataSailr script consists of three major blocks, TOPLEVEL, DATA, and PROC. TOPLEVEL loads and saves datasets. DATA blocks utilize DataSailr package as its backend, which enables wrting data manipulation insturctions in a rowwise way. PROC blocks have a series of PROC instructions, which are converted to R functions and are executed sequentially.


### Quick Introduction

The following is an example of StatSailr script. It consists of TOPLEVEL instruction, DATA block and PROC blocks.

```
READ builtin="mtcars"

DATA new_mtcars set=mtcars
  if(hp > 100){
    powerful = 1
  }else{
    powerful = 0
  }
END

PROC PRINT data=new_mtcars
  head 10
END

PROC REG data=new_mtcars
  lm hp ~ powerful
END
```

Save this script as, say, create_new_mtcars.slr and run.

```
# From command line
# By installing statsailr gem, sailr command should become available.

sailr create_new_mtcars.slr
```


### Commands and options

#### sailr

sailr command executes StatSailr script.

* sailr [filename]
    + --procs-gem <gemX,gemY,...>
        + allow users to specify PROCs gems when they need to use other than default PROCs gem, statsailr_procs_base.
        + To specify multiple gems, separate them with comma(,)


#### sailrREPL

Not only sailr command, but sailrREPL command is also provided. It enables interactive executaion of StatSailr script. (For non-UNIX system, sailrREPL --thread can be used, which is thread based.)

* sailrREPL
    + --procs-gem <gemX,gemY,...>
        + allow users to specify PROCs gems
    + --thread
        + Thread based implementation of REPL. (Windows requires this option.)


sailrREPL requires the explicit commands. Lines are stored as input script until the following commands are executed. Commands within REPL start from !.


+ !! or !exec : Executes StatSailr script input. (and clears the input stored.)
+ !clear : Clears input script.
+ !exit : Finishes StatSailr REPL.


The following example shows how sailrREPL works.

```
cli > sailrREPL  # start REPL

(^^)v: READ builtin=mtcars
(^^)v: !!  # execute READ
  ... output ...
(^^)v: DATA new_mtcars set=mtcars
(^^)v:   if( hp > 100){
(^^)v:     powerful = 1
(^^)v:   }else{
(^^)v:     powerful = 0
(^^)v:   }
(^^)v: END
(^^)v: !!  # execute DATA block
  ... output ...
(^^)v: PROC PRINT data=new_mtcars
(^^)v:   head 5
(^^)v: END
(^^)v: !!  # execute PROC block
  ... output ...
(^^)v: !exit  # exit REPL

cli > 

```

## Installation

### Requirements

* R (>= 4.0 is preferable)
    + datasailr package
        + From R's interpreter, execute 'install.packages("datasailr")'.
* Ruby (>= 2.7)
    + r_bridge gem
        + Configure PATH, LD_LIBRARY_PATH or RUBY_DLL_PATH to access R's shared library (libR.so or R.dll).
            + Details are mentioned in r_bridge gem's README.
        + After configuring these settings, install r_bridge gem via 'gem install r_bridge'


### Install StatSailr

```
$ gem install statsailr
```

* Then, 'sailr' and 'sailrREPL' become available.


## Grammar of StatSalr

StatSailr script consists of three parts, TOPLEVEL, DATA block and PROC block.

The following shows structures of these blocks. Details about TOPLEVEL, DATA and PROC blocks are documented in the [StatSailr official site](https://statsailr.io)


### TOPLEVEL statement

TOPLEVEL statements import and save datasets, and also StatSailr's current working directory.


* import and save datasets.

Datasets can come from built-in datasets and files. In R, built-in datasets can be used by data() function, and StatSailr READ with 'builtin=' option does the same job.

When importing datasets from files, currently there are three types of files availble, RDS, RDATA and CSV. RDS contains a single R object, and when you import it, you can neme the object using 'as=' option. If you omit 'as=' option, the name is created based on the filename. RDATA can contain multiple R objects, but their names cannot be changed when importing that are decided when saveing. CSV is a comma separated values file.

These dataset types are decided as follows. If you specify 'type' option, its type is used. If you do not specify it, it is inferred from the file extension. 


```
READ builtin="mtcars"
READ file="./mtcars.rds" type="rds" as="mtcars"
READ file="./mtcars.rda" type="rdata"
READ file="./mtcars.csv" type="csv" # 'as=' can be used optionally.
```

For StatSailr SAVE, specifying dataset name(s) followed by 'file=' option is required. "type=" option can be omitted, and in such a case, file extension is used to infer the file type.

```
SAVE new_mtcars file="./new_mtcars.rds" type="rds"
SAVE mtcars new_mtcars file="./new_mtcars.rda" type="rdata"
SAVE new_mtcars file="./new_mtcars.csv" type="csv"
```

* show and change working directory

The concept of working directory is really important. If you run your SailrScript in an unintentional place and ouput some data, those data might overwrite your importan data.

The default working directory should be the directory where StatSailr script file exists. If you do not specify script file, such as when you run REPL, the default working directory should be the directory where you start your command (such as REPL).

The following commands show the current working directory and change it to new directory.

```
GETWD
SETWD "~/sailr_workspace"
```


### DATA block

DATA block starts with the line of DATA, new dataset name and DATA options. For DATA options, 'set=' option is required which specify the input dataset. (Note that unlinke PROC options where 'data=' usually speifies input dataset, "set=" does the same job in DATA block. This difference comes from just an aesthetic reason.) Lines that follws the first DATA line represent how to manipulate input dataset. The lines are writtein in DataSailr script. END keyword specifies the end of DATA block.

```
DATA new_dataset set=ori_dataset
  // This part is a plain DataSailr script
  // (e.g.)
  if(hp > 100){
    powerful = 1
  }else{
    powerful = 0
  }
END
```

The DataSailr script is described in detail at [its official website](https://datasailr.io).

Briefly speaking, 

1. Rowwise dataset manipulation
    + Varables correspond to column names.
2. Simplified available types
    + Int, Double and String(=Characters) are basic types, that can be used in DataSailr script and also those values can be assigned to column value (of dataset).
    + Regular expression and boolean are not assigned to dataset. They can be held by variables, but do not modify dataset.
        + Regular expression is used for if condition and extracting substrings.
        + Boolean is internal type that is used for if condition.
3. Assignment operator (=) creates new column with the column name same as the variable left-hand-side(LHS) of assignment operator.
    + If the variable already exits, the column is updated.
    + Exceptions are assigning regular expressions and boolen, which do not modify dataset. Variables pointing to those objects are only used in the script.
4. Control flow can be done using if-(else if)-(else) statement.
    + Condition part needs parentheses (), and statement part require curly braces.
5. Arithmetic operators
6. Built-in functions
    + Mainly used to manipulate strings.
7. Regular expression
8. UTF-8
    + Use UTF-8 for script and dataset. It is highly recommended that dataset should be saved using UTF-8 beforehand.
9. push!() and discard!() built-in functions
    + push!() can create multiple rows from current row.
    + discard!() can filter out specific rows by being used with if statements.


### PROC block

#### statsailr_procs_base gem

PROC commands and instructions are now managed in a separate PROCs gem. The gem name is 'statsailr_procs_base' (from ver. 0.71). You need to have the gem installed to use PROCs ,though it is usually installed as a dependency of 'statsailr' gem. If StatSailr complains that PROC PRINT command is not found, please make sure that the PROCs gem is installed.

The PROCs gem holds basic PROC settings, such as PRINT and PLOT, and its main class (StatSailr::ProcsBase) just returns the base path for those PROC settings. Please read the README of the PROCs gem if you are interested in how PROCs are implemented.


#### Format

A typical PROC block looks like the follwing. The first line start with PROC, followed by PROC command name and PROC options. The PROC first line is followed by a list of instuctions with their main and optional arguments. The PROC block ends with END keyword.

```
PROC COMMAND proc_opts
  instX main_arg / opt_args  # proc_statement X
  instY main_arg / opt_args
  instZ main_arg / opt_args
END
```

* COMMAND
    + PROC command name
* proc_opts
    + This parameter can be refered from any instructions in this block. In other words, this can be seen as global settings of this PROC block.
    + Internally, this parameter is managed by RBridge::ParamManager.
* proc_statement line
    + Each line consists of instruction, main argument and optional arguments. Main argument and optional arguments are separated by slash(/).
    + Internally, each line is converted into an R function, and its return value is managed by RBridge::ResultManager. (Whether the result is stored or not can be changed in PROC setting.) 
        + inst
            + PROC instruction name. Instruction names are associated with R's function names.
        + main_arg
            + Main argument. Value specified in main_arg is passed to R function's argument.
            + How main argument part is parsed varies on each instruction. This is defined in main_arg_and_how_to_treat variable in setting.
        + opt_args
            + Optional arguments. Values specified in opt_args are also passed to R function's argument.
            + opt_args part consists of (a) key-value(s) or key(s).
            + Internally, this argument parsing is conducted by methods in STSBlockParseProcOpts.


## About plotting device

R outputs graphics to various programs called devices. When using R interactively, graphics are usually output to a window by default. StatSailr uses such a default device, and the device or the plotting window closes as the script execution finishes. 

To keep the plotting result, it is currently recommended to copy the device graphics to some file. dev.copy() does this work. For such PROCs that have plot related instructions, dev.copy instruction are provided. dev.copy can save the graphic on the current graphics device to a file.

```
// Example

PROC PLOT data=mtcars
  scatter cyl carb   // This instruction creates scatter plot and displays it on a device (window).
  dev.copy png / file="./myplot.png"  // This instruction copies graphics on the device to myplot.png file.
END
```


## License

The gem is available as open source under the terms of the [GPL v3 License](https://www.gnu.org/licenses/gpl-3.0.en.html).


## Contact

Your feedback is welcome.

Maintainer: Toshi Umehara toshi@niceume.com



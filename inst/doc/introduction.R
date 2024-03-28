# <unlabeled code block>
water <- data.frame(
   name        = c("Ross", "Robert", "Martin", "Brian", "Simon")
 , consumption = c(110, 105, 0.15, 95, -100) 
)
water

# <unlabeled code block>
library(dcmodify)
# define a rule set (here with one rule)
rules <- modifier(
          if ( abs(consumption) <= 1 ) consumption <- 1000*consumption  
        , if ( consumption < 0 ) consumption <- -1 * consumption )  

# apply the ruleset to the data
out <- modify(water, rules)
out

# <unlabeled code block>
rules

# <unlabeled code block>
modify(water, rules[2])

# <unlabeled code block>
variables(rules)

# <unlabeled code block>
rules <- modifier(.file="myrules.txt")
rules

# <unlabeled code block>
fn <- tempfile()
# export rules to yaml format
export_yaml(rules,file=fn)

# print file contents
readLines(fn) |> paste(collapse="\n") |> cat()

# <unlabeled code block>
d <- data.frame(
    name = c("U1","S1")
  , label = c("Unit error", "sign error")
)
d$rule <- c(
   "if(abs(consumption)<=1) consuption <- 1000 * consumption"
  ,"if(consumption < 0) consumption <- -1 * consumption"
)
d

# <unlabeled code block>
myrules <- modifier(.data=d)
myrules

# <unlabeled code block>
dat <- data.frame(x=seq_len(nrow(women)))
m   <- modifier(if (x > 2) x <- ref$height/2)
out <- modify(dat, m, ref=women)
head(out)

# <unlabeled code block>
m   <- modifier(if (x > 2) x <- women$height/2)
out <- modify(dat, m, ref=list(women=women))
head(out,3)

# <unlabeled code block>
e <- new.env()
e$women <- women
m   <- modifier(if (x > 2) x <- women$height/2)
out <- modify(dat, m, ref=e)
head(out,3)

# <unlabeled code block>
library(lumberjack)
# create a logger (see ?cellwise)
lgr <- cellwise$new(key="name")
# create rules

rules <- modifier(
          if ( abs(consumption) <= 1 ) consumption <- 1000*consumption  
        , if ( consumption < 0 ) consumption <- -1 * consumption )  

# apply rules, and pass logger object to modify()
out <- modify(water, rules, logger=lgr)

# check what happened, by dumping the log and reading in 
# the csv.
logfile <- tempfile()
lgr$dump(file=logfile)
read.csv(logfile)


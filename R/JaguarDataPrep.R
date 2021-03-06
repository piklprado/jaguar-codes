#'
#' #  **Jaguar Data Preparation**
#' 
#' #### *Alan E. de Barros, Bernardo Niebuhr, Vanesa Bejarano, Julia Oshima,Claudia Kanda, Milton Ribeiro, Ronaldo Morato,Paulo Prado*
#' date: "March, 08 2019"
#' ##### Scripts adapted from Bernardo Niebuhr data preparation, and Luca Borger and John Fieberg's lectures.
#'
#'
#' 
#' 
#' #### *Preamble*
#' For a fresh start, clean everything in working memory
rm(list= ls())                                                 
#' 
#' Install and load packages
if(!require(install.load)) install.packages('install.load'); library(install.load)
install.load::install_load("move", "adehabitatLT", "amt") # Movement packages
install.load::install_load("maptools", "raster", "rgdal","sp") # Spatial packages
install.load::install_load("colorspace","ggmap", "rgl", "lattice", "leaflet") # Visualization packages
install.load::install_load("RCurl", "dplyr", "readr", "lubridate", "tibble") # Aux packages
install.load::install_load("circular", "caTools") # Stats packages
install.load::install_load("knitr", "ezknitr") # To render documents 
#'

#'
#' ### Source functions from GitHub local directory 
# Do not required to set directory if Rscript have been opened from the GitHub local directory
source("DataPrepFunctions.R") 
#'
#' #### Load the data and create a dataframe object:
mov.data.org <- read.delim(file="../data/mov.data.org.txt")
mov.data.org <- dplyr::select(mov.data.org, -(individual.taxon.canonical.name:tag.local.identifier))
#'
#' #### Add Individual info  (see older development files for details)
info <- read.delim(file="../data/info.txt")
#'
#' #### Merge movement with individual info/parameters
merged<- merge(mov.data.org,info)
mov.data.org <- merged 
#'
#' #### Organize data
#' 
#' Test
#' get.year(time.stamp = mov.data.org$timestamp[10000])
#' 
#' All individuals
year <- as.numeric(sapply(mov.data.org$timestamp, get.year))
#' Add 1900/2000
new.year <- as.character(ifelse(year > 50, year + 1900, year + 2000))
#' Test
set.year(time.stamp = as.character(mov.data.org$timestamp[10000]), year = '2013')
#' All individuals
date.time <- as.character(mapply(set.year, as.character(mov.data.org$timestamp),
                                 new.year))
#' Date/Time as POSIXct object
mov.data.org$timestamp.posix <- as.POSIXct(date.time, 
                                           format = "%m/%d/%Y %H:%M", tz = 'UTC')
mov.data.org$GMTtime <- mov.data.org$timestamp.posix
#'
#'
#' ## Get local time
#'  
#' A column to represent the local timezone (already with the - signal) has been included to then multiply the timestamp and get the difference:
mov.data.org$local_time <- mov.data.org$timestamp.posix + mov.data.org$timezone*60*60
mov.data.org$timestamp.posix <- mov.data.org$local_time 
#' Now all the (timestamp.posix)'s calculations are based on local time
#' #### *Note: UTC has also been assigned to the local time here. But the correct timezones of each region are assigned below*
#' 
#' 
#' ### Adjusting for Movement Packages
#' ### adehabitatLT
#'
#' Transforms in ltraj object
coords <- data.frame(mov.data.org$location.long, mov.data.org$location.lat)
mov.traj <- as.ltraj(xy = coords, date=mov.data.org$timestamp.posix, 
                     id=mov.data.org$individual.local.identifier..ID., 
                     burst=mov.data.org$individual.local.identifier..ID., 
                     infolocs = mov.data.org[,-c(3:6, ncol(mov.data.org))])
mov.traj.df <- ld(mov.traj)
#'
#'
#' ### move
#' Organize data as a move package format
move.data <- move(x = mov.traj.df$x, y = mov.traj.df$y, 
                  time = mov.traj.df$date, 
                  proj = CRS('+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs'),
                  data = mov.traj.df, animal = mov.traj.df$id, sensor = 'GPS')
#' move.data  (moveStack)
#' Separate individual animals' trajectories and convert move object to a dataframe
# unstacked <- split(move.data)
jaguar_df <- as(move.data, "data.frame")

#' Reclassifying variables
age <- as.numeric(levels(jaguar_df$age))[jaguar_df$age]
weight <- as.numeric(levels(jaguar_df$weight))[jaguar_df$weight]
jaguar_df$id <- as.factor(jaguar_df$individual.local.identifier..ID.)  
jaguar_df$age <- age   
jaguar_df$weight <- weight  
#'
#' Cleaning up columns which will be in excess due to repetition of analysis 
jaguar_df$dx <- NULL
jaguar_df$dy <- NULL
jaguar_df$dist <- NULL
jaguar_df$R2n <- NULL
jaguar_df$abs.angle <- NULL
jaguar_df$rel.angle  <- NULL
jaguar_df$location.lat <- NULL
jaguar_df$timestamps  <- NULL
jaguar_df$sensor <- NULL
jaguar_df$burst <- NULL
jaguar_df$optional <- NULL
jaguar_df$coords.x1 <- NULL
jaguar_df$coords.x2 <- NULL
jaguar_df$trackId <- NULL
jaguar_df$individual.local.identifier..ID.<- NULL
jaguar_df$study.name <- NULL
jaguar_df$collar_type <- NULL  
jaguar_df$brand <- NULL
jaguar_df$local_time <- NULL
jaguar_df$Event_ID  <- NULL
#jaguar_df$timezone <- NULL
# jaguar_df$dt <- NULL
#'
#' Create columns for different time periods
jaguar_df$week <- as.numeric(strftime(as.POSIXlt(jaguar_df$timestamp.posix),format="%W"))
jaguar_df$day <- as.numeric(strftime(as.POSIXlt(jaguar_df$timestamp.posix),format="%j"))
jaguar_df$year <- as.numeric(strftime(as.POSIXlt(jaguar_df$timestamp.posix),format="%Y"))
jaguar_df$hour <- as.numeric(strftime(as.POSIXlt(jaguar_df$timestamp.posix),format="%H"))
jaguar_df$min <- as.numeric(strftime(as.POSIXlt(jaguar_df$timestamp.posix),format="%M"))
jaguar_df$time <- jaguar_df$hour + (jaguar_df$min)/60
#' Day, Night and riseset (Sunrise or Sunset)
# day  7 to 16  and  night 19 to 4 and  sun riseset 5,6,17,18
#jaguar_df$month=as.numeric(substr(jaguar_df$date,6,7))
jaguar_df$period=ifelse(jaguar_df$hour==7,"day",
                        ifelse(jaguar_df$hour==8,"day",
                        ifelse(jaguar_df$hour==9,"day", 
                        ifelse(jaguar_df$hour==10,"day", 
                        ifelse(jaguar_df$hour==11,"day", 
                        ifelse(jaguar_df$hour==12,"day", 
                        ifelse(jaguar_df$hour==13,"day", 
                        ifelse(jaguar_df$hour==14,"day",
                        ifelse(jaguar_df$hour==15,"day",
                        ifelse(jaguar_df$hour==16,"day",
                        ifelse(jaguar_df$hour==19,"night",
                        ifelse(jaguar_df$hour==20,"night",
                        ifelse(jaguar_df$hour==21,"night",
                        ifelse(jaguar_df$hour==22,"night", 
                        ifelse(jaguar_df$hour==23,"night",
                        ifelse(jaguar_df$hour==0,"night",
                        ifelse(jaguar_df$hour==1,"night",
                        ifelse(jaguar_df$hour==2,"night",
                        ifelse(jaguar_df$hour==3,"night",
                        ifelse(jaguar_df$hour==4,"night","riseset"))))))))))))))))))))

#'
#' ### More Data checking and cleaning 
#'
#' Delete observations where missing lat or long or a timestamp. (There are no missing observations but it is a good practice)
ind<-complete.cases(jaguar_df[,c("y","x","date")])
jaguar_df<-jaguar_df[ind==TRUE,]
#'
#" Check order (data should already be ordered)
jaguar_ord <- jaguar_df[order(jaguar_df$id,jaguar_df$date),]
all.equal(jaguar_df,jaguar_ord)
#'
#' Check for duplicated observations (ones with same lat, long, timestamp,
#'  and individual identifier). No duplicate observations in this data set
ind2<-jaguar_df %>% select("date","x","y","id") %>% duplicated
#' sum(ind2) # no duplicates
jaguar_df<-jaguar_df[ind2!=TRUE,]
#'
#' Clean suspectly close points!!!  Above 1200 secs or 20 min minimal interval 
excludes <- filter(jaguar_df, dt < 1200)
removed<- anti_join(jaguar_df, excludes)
jaguar_df <- removed 
#'
#'
#'
#'
#' ### Add UTMs and POSIX timezone
#' #### Grouping project regions when they occur within the same UTM and time zone
# Code with function => crs.convert
#' 
#' 
#' ###    ATLANTIC FOREST WEST    (Project regions 1 and 2)
#'
#' 1) Atlantic Forest W1
AFW1 <- crs.convert(data = subset(jaguar_df,project_region=='Atlantic Forest W1'),
                    crs.input = "+proj=longlat +datum=WGS84",
                    crs.output = "+proj=utm +zone=22K +south +datum=WGS84 +units=m +no_defs",
                    point.names = c("utm_x", "utm_y", "long_x", "lat_y"))
AFW1$date <- as.character(AFW1$date)
AFW1$date <- as.POSIXct(AFW1$date, format ="%Y-%m-%d %H:%M:%S", tz = "Etc/GMT+3") 
#'
#' 2) Atlantic Forest W2
AFW2 <- crs.convert(data =subset(jaguar_df,project_region=='Atlantic Forest W2'),
                    crs.input = "+proj=longlat +datum=WGS84",
                    crs.output = "+proj=utm +zone=22K +south +datum=WGS84 +units=m +no_defs",
                    point.names = c("utm_x", "utm_y", "long_x", "lat_y"))
AFW2$date <- as.character(AFW2$date)
AFW2$date <- as.POSIXct(AFW2$date, format ="%Y-%m-%d %H:%M:%S", tz = "Etc/GMT+3") 
#'
#' Atlantic Forest West
AFW=rbind(AFW1,AFW2)

#'
#'
#' ### CAATINGA   
#'
#' 3) Caatinga
Caatinga <- crs.convert(data = subset(jaguar_df,project_region=='Caatinga'),
                    crs.input = "+proj=longlat +datum=WGS84",
                    crs.output = "+proj=utm +zone=23L +south +datum=WGS84 +units=m +no_defs",
                    point.names = c("utm_x", "utm_y", "long_x", "lat_y"))
Caatinga$date <- as.character(Caatinga$date)
Caatinga$date <- as.POSIXct(Caatinga$date, format ="%Y-%m-%d %H:%M:%S", tz = "Etc/GMT+3") 

#'
#'
#'
#' ### CERRADO   2 Projects (4 and 5)
#'
#' 4)  Cerrado1
#' 
Cerrado1<- crs.convert(data = subset(jaguar_df,project_region=='Cerrado1'),
                       crs.input = "+proj=longlat +datum=WGS84",
                       crs.output = "+proj=utm +zone=22K +south +datum=WGS84 +units=m +no_defs",
                       point.names = c("utm_x", "utm_y", "long_x", "lat_y"))
Cerrado1$date <- as.character(Cerrado1$date)
Cerrado1$date <- as.POSIXct(Cerrado1$date, format ="%Y-%m-%d %H:%M:%S", tz = "Etc/GMT+3") 


#'
#' 5)  Cerrado2
#' 
Cerrado2<- crs.convert(data = subset(jaguar_df,project_region=='Cerrado2'),
                       crs.input = "+proj=longlat +datum=WGS84",
                       crs.output = "+proj=utm +zone=22L +south +datum=WGS84 +units=m +no_defs",
                       point.names = c("utm_x", "utm_y", "long_x", "lat_y"))
Cerrado2$date <- as.character(Cerrado2$date)
Cerrado2$date <- as.POSIXct(Cerrado2$date, format ="%Y-%m-%d %H:%M:%S", tz = "Etc/GMT+3") 
Cerrado=rbind(Cerrado1,Cerrado2)

#'
#'
#' ### COSTA RICA
#'
#' 6) Costa Rica
#'
#'
CRica<- crs.convert(data = subset(jaguar_df,project_region=='Costa Rica'),
                       crs.input = "+proj=longlat +datum=WGS84",
                       crs.output = "+proj=utm +zone=16P +north +datum=WGS84 +units=m +no_defs",
                       point.names = c("utm_x", "utm_y", "long_x", "lat_y"))
CRica$date <- as.character(CRica$date)
CRica$date <- as.POSIXct(CRica$date, format ="%Y-%m-%d %H:%M:%S", tz = "Etc/GMT+6") 


#'
#'
#' ###   DRY CHACO 
#' Transforming coordinate to UTM # ids: 16,70 => (most 20K), ids: 76,77 => (20 K); ids: 71,72,73 => (21 K) 
#' 
Drych=subset(jaguar_df,project_region=='Dry chaco')
X16=subset(Drych,id=='16')
X70=subset(Drych,id=='70')
X71=subset(Drych,id=='71')
X72=subset(Drych,id=='72')
X73=subset(Drych,id=='73')
X76=subset(Drych,id=='76')
X77=subset(Drych,id=='77')
#'  Drych1 and Drych2
Drych1=rbind(X16,X70,X76,X77)
Drych2=rbind(X71,X72,X73)
#'
#' 7) Drych1    
# 76,77  Zone 20 K; 16 & 70 (most is in Zone 20 K too, but a little bit in 21K)
Drych1<- crs.convert(data = Drych1,
                    crs.input = "+proj=longlat +datum=WGS84",
                    crs.output = "+proj=utm +zone=20K +south +datum=WGS84 +units=m +no_defs",
                    point.names = c("utm_x", "utm_y", "long_x", "lat_y"))
Drych1$date <- as.character(Drych1$date)
Drych1$date <- as.POSIXct(Drych1$date, format ="%Y-%m-%d %H:%M:%S", tz = "Etc/GMT+4") 

#' 
#'
#' 8) Drych2  
# 71,72,73 => (21 K)
Drych2<- crs.convert(data = Drych2,
                     crs.input = "+proj=longlat +datum=WGS84",
                     crs.output = "+proj=utm +zone=21K +south +datum=WGS84 +units=m +no_defs",
                     point.names = c("utm_x", "utm_y", "long_x", "lat_y"))
Drych2$date <- as.character(Drych2$date)
Drych2$date <- as.POSIXct(Drych2$date, format ="%Y-%m-%d %H:%M:%S", tz = "Etc/GMT+4") 
# Dry Chaco Total
Drych=rbind(Drych1,Drych2)
#'
#'

#' ###  HUMID CHACO
#' 
#' 9) Humid Chaco  
#'      
Hch<- crs.convert(data = subset(jaguar_df,project_region=='Humid chaco'),
                    crs.input = "+proj=longlat +datum=WGS84",
                    crs.output = "+proj=utm +zone=21K +south +datum=WGS84 +units=m +no_defs",
                    point.names = c("utm_x", "utm_y", "long_x", "lat_y"))
Hch$date <- as.character(Hch$date)
Hch$date <- as.POSIXct(Hch$date, format ="%Y-%m-%d %H:%M:%S", tz = "Etc/GMT+4") 

#' 
#' 

#' ###  FOREST PARAGUAY 
#' 
#' 10) Forest Paraguay   
#' 
FPy<- crs.convert(data = subset(jaguar_df,project_region=='Forest Paraguay'),
                  crs.input = "+proj=longlat +datum=WGS84",
                  crs.output = "+proj=utm +zone=21J +south +datum=WGS84 +units=m +no_defs",
                  point.names = c("utm_x", "utm_y", "long_x", "lat_y"))
FPy$date <- as.character(FPy$date)
FPy$date <- as.POSIXct(FPy$date, format ="%Y-%m-%d %H:%M:%S", tz = "Etc/GMT+4") 

#' 
#'
#'
#' ### IGUAZU
#'
Iguazu=subset(jaguar_df,project_region=='Iguazu')
# Transforming coordinate to UTM   # 42,66,80,90 => (21 J);      83 => (22 J) 
X42=subset(Iguazu,id=='42')
X66=subset(Iguazu,id=='66')
X80=subset(Iguazu,id=='80')
X90=subset(Iguazu,id=='90')
X83=subset(Iguazu,id=='83')
#'  Iguazu1 and Iguazu2
Iguazu1=rbind(X42,X66,X80,X90)
Iguazu2=(X83)
#'
#' 11) Iguazu1    
# 42,66,80,90 => ( Zone 21 J)
Iguazu1<- crs.convert(data = Iguazu1,
                     crs.input = "+proj=longlat +datum=WGS84",
                     crs.output = "+proj=utm +zone=21J +south +datum=WGS84 +units=m +no_defs",
                     point.names = c("utm_x", "utm_y", "long_x", "lat_y"))
Iguazu1$date <- as.character(Iguazu1$date)
Iguazu1$date <- as.POSIXct(Iguazu1$date, format ="%Y-%m-%d %H:%M:%S", tz = "Etc/GMT+3") 

#'
#'
#' 12) Iguazu2    
#  83 => (22 J) 
Iguazu2<- crs.convert(data = Iguazu2,
                      crs.input = "+proj=longlat +datum=WGS84",
                      crs.output = "+proj=utm +zone=22J +south +datum=WGS84 +units=m +no_defs",
                      point.names = c("utm_x", "utm_y", "long_x", "lat_y"))
Iguazu2$date <- as.character(Iguazu2$date)
Iguazu2$date <- as.POSIXct(Iguazu2$date, format ="%Y-%m-%d %H:%M:%S", tz = "Etc/GMT+3") 
#' Iguazu
Iguazu=rbind(Iguazu1,Iguazu2)
#'
#'
#' ###  AMAZONIA
#' 
#' 13)  Amazonia Mamiraua (Brazil) - Flooded Amazonia
Mamiraua<- crs.convert(data = subset(jaguar_df,project_region=='Mamiraua'),
                  crs.input = "+proj=longlat +datum=WGS84",
                  crs.output = "+proj=utm +zone=20M +south +datum=WGS84 +units=m +no_defs",
                  point.names = c("utm_x", "utm_y", "long_x", "lat_y"))
Mamiraua$date <- as.character(Mamiraua$date)
Mamiraua$date <- as.POSIXct(Mamiraua$date, format ="%Y-%m-%d %H:%M:%S", tz = "Etc/GMT+4") 

#' 
#'
#' Dry Amazonia, PA, translocated 
#' 14) IOP Para Amazonia   
# Translocated animal   
iopPA<- crs.convert(data = subset(jaguar_df,id=='24'),
                       crs.input = "+proj=longlat +datum=WGS84",
                       crs.output = "+proj=utm +zone=22M +south +datum=WGS84 +units=m +no_defs",
                       point.names = c("utm_x", "utm_y", "long_x", "lat_y"))
iopPA$date <- as.character(iopPA$date)
iopPA$date <- as.POSIXct(iopPA$date, format ="%Y-%m-%d %H:%M:%S", tz = "Etc/GMT+3") 

#'
#'
#' ###   MEXICO
#'
#'  Greater Lacandona  15) Mexico 
Lacandona<- crs.convert(data = subset(jaguar_df,project_region=='Greater Lacandona'),
                    crs.input = "+proj=longlat +datum=WGS84",
                    crs.output = "+proj=utm +zone=15Q +south +datum=WGS84 +units=m +no_defs",
                    point.names = c("utm_x", "utm_y", "long_x", "lat_y"))
Lacandona$date <- as.character(Lacandona$date)
Lacandona$date <- as.POSIXct(Lacandona$date, format ="%Y-%m-%d %H:%M:%S", tz = "Etc/GMT+6") 

#'  
#'
#' Mexico East  16) 
MexEast<- crs.convert(data = subset(jaguar_df,project_region=='Mexico East'),
                        crs.input = "+proj=longlat +datum=WGS84",
                        crs.output = "+proj=utm +zone=16Q +south +datum=WGS84 +units=m +no_defs",
                        point.names = c("utm_x", "utm_y", "long_x", "lat_y"))
MexEast$date <- as.character(MexEast$date)
MexEast$date <- as.POSIXct(MexEast$date, format ="%Y-%m-%d %H:%M:%S", tz = "Etc/GMT+6") 

#'  
#'
#' Mexico Sonora 17) 
Sonora<- crs.convert(data = subset(jaguar_df,project_region=='Mexico Sonora'),
                      crs.input = "+proj=longlat +datum=WGS84",
                      crs.output = "+proj=utm +zone=12R +south +datum=WGS84 +units=m +no_defs",
                      point.names = c("utm_x", "utm_y", "long_x", "lat_y"))
Sonora$date <- as.character(Sonora$date)
Sonora$date <- as.POSIXct(Sonora$date, format ="%Y-%m-%d %H:%M:%S", tz = "Etc/GMT+7") 

#'
#'  Mexico
Mex=rbind(Lacandona,MexEast,Sonora)

#'
#'
#'
#' ###  PANTANAL 
#' 
#' 18) PantanalTotal Brazil&Paraguay   -  7 Projects in total, all in the same UTM zone
#' 
Pantanal<- crs.convert(data = subset(jaguar_df,project_bioveg=='Pantanal'),
                     crs.input = "+proj=longlat +datum=WGS84",
                     crs.output = "+proj=utm +zone=21K +south +datum=WGS84 +units=m +no_defs",
                     point.names = c("utm_x", "utm_y", "long_x", "lat_y"))
Pantanal$date <- as.character(Pantanal$date)
Pantanal$date <- as.POSIXct(Pantanal$date, format ="%Y-%m-%d %H:%M:%S", tz = "Etc/GMT+4") 

#'
#'
#' ###  Jaguar Dataframe with UTMs  
#' head(AFW1);head(AFW2);head(Caatinga);head(Cerrado1);head(Cerrado2);head(CRica);head(Pantanal);head(Drych1);str(Drych)
#' head(Hch);head(FPy);head(Iguazu1);head(Iguazu2);head(Mamiraua);head(iopPA);head(Lacandona);head(MexEast);head(Sonora)
#'
#' #### *Important Note: A single dataframe canot hold multiple POSIX*
#' This will assign the POSIXct of the first region (AFW in this case). 
#' Hence it is required to store the regional POSIXct in multiple dataframes (or within a tibble for example)
jaguar_df=rbind(AFW1,AFW2,Caatinga,Cerrado1,Cerrado2,CRica,Pantanal,Drych1,Drych2,Hch,FPy,Iguazu1,Iguazu2,Mamiraua,iopPA,Lacandona,MexEast,Sonora)
#' Need re-order the data again and create a new Event_ID
jaguar_ord <- jaguar_df[order(jaguar_df$id,jaguar_df$date),]
jaguar_df <- jaguar_ord
jaguar_df$Event_ID <- seq.int(nrow(jaguar_df))
#' We assign UTC again just to store a full dataframe with UTMS but bellow we use regional POSIXct to create trks (amt package).
jaguar_df$date <- jaguar_df$timestamp.posix

#' In case we want save and read it as txt
# write.table(jaguar_df,file="../data/jaguar_df.txt",row.names = F,quote=F,col.names=T,sep="\t")
# jaguar <- read.delim(file="../data/jaguar_df.txt")
#' 
#' 
#' 

#' 
#' ## Creating tracks in amt 
#' #### Based on UTM, project regions and timezones (Commom to both RSF and SSF)
#' 
#' ### ATLANTIC FOREST WEST  (Project regions 1 and 2)
#'
#' Atlantic Forest West
AFWtrk <- trk.convert(data = AFW,
                      .x=utm_x,
                      .y=utm_y,
                      .t=date,
                      id=id,
                      project_region=project_region,
                      sex=sex,
                      age=age,
                      weight=weight, 
                      status=status,
                      period=period,
                      long_x=long_x,
                      lat_y=lat_y,
                      crs = CRS("+proj=utm +zone=22K +south +datum=WGS84 +units=m +no_defs"))
#' Objects for AFW project regions
 AFW1trk=AFWtrk %>% filter(project_region == "Atlantic Forest W1")
 AFW2trk=AFWtrk %>% filter(project_region == "Atlantic Forest W2")

#'###  CAATINGA 
#'
#' 3) Caatinga   
Caatingatrk <- trk.convert(data = Caatinga,
                      .x=utm_x,
                      .y=utm_y,
                      .t=date,
                      id=id,
                      project_region=project_region,
                      sex=sex,
                      age=age,
                      weight=weight, 
                      status=status,
                      period=period,
                      long_x=long_x,
                      lat_y=lat_y,
                      crs = CRS("+proj=utm +zone=23L +south +datum=WGS84 +units=m +no_defs"))


#'
#' ###  CERRADO   (2 Projects: 4 and 5)
#' 
#' 4) Cerrado1   
Cerrado1trk <- trk.convert(data = Cerrado1,
                           .x=utm_x,
                           .y=utm_y,
                           .t=date,
                           id=id,
                           project_region=project_region,
                           sex=sex,
                           age=age,
                           weight=weight, 
                           status=status,
                           period=period,
                           long_x=long_x,
                           lat_y=lat_y,
                           crs = CRS("+proj=utm +zone=22K +south +datum=WGS84 +units=m +no_defs"))

#' 5) Cerrado2   
Cerrado2trk <- trk.convert(data = Cerrado2,
                           .x=utm_x,
                           .y=utm_y,
                           .t=date,
                           id=id,
                           project_region=project_region,
                           sex=sex,
                           age=age,
                           weight=weight, 
                           status=status,
                           period=period,
                           long_x=long_x,
                           lat_y=lat_y,
                           crs = CRS("+proj=utm +zone=22L +south +datum=WGS84 +units=m +no_defs"))

#' Cerradotrk
Cerradotrk=rbind(Cerrado1trk,Cerrado2trk)
#'


#'
#' ###  COSTA RICA  
#' 
#' 6) Costa Rica
CRicatrk <- trk.convert(data = CRica,
                          .x=utm_x,
                          .y=utm_y,
                          .t=date,
                          id=id,
                          project_region=project_region,
                          sex=sex,
                          age=age,
                          weight=weight, 
                          status=status,
                          period=period,
                          long_x=long_x,
                          lat_y=lat_y,
                          crs = CRS("+proj=utm +zone=16P +north +datum=WGS84 +units=m +no_defs"))

#' ### DRY CHACO
#'
#' 7) Drych1
Drych1trk <- trk.convert(data = Drych1,
                        .x=utm_x,
                        .y=utm_y,
                        .t=date,
                        id=id,
                        project_region=project_region,
                        sex=sex,
                        age=age,
                        weight=weight, 
                        status=status,
                        period=period,
                        long_x=long_x,
                        lat_y=lat_y,
                        crs = CRS("+proj=utm +zone=20K +south +datum=WGS84 +units=m +no_defs"))
#' 8) Drych2
Drych2trk <- trk.convert(data = Drych2,
                         .x=utm_x,
                         .y=utm_y,
                         .t=date,
                         id=id,
                         project_region=project_region,
                         sex=sex,
                         age=age,
                         weight=weight, 
                         status=status,
                         period=period,
                         long_x=long_x,
                         lat_y=lat_y,
                         crs = CRS("+proj=utm +zone=21K +south +datum=WGS84 +units=m +no_defs"))

#'
#'  DRY CHACO trk => Drychtrk
Drychtrk=rbind(Drych1trk,Drych2trk)
#'
#'

#' ### HUMID CHACO  
#' 
#' 9) Humid Chaco       
Hchtrk <- trk.convert(data = Hch,
                         .x=utm_x,
                         .y=utm_y,
                         .t=date,
                         id=id,
                         project_region=project_region,
                         sex=sex,
                         age=age,
                         weight=weight, 
                         status=status,
                         period=period,
                         long_x=long_x,
                         lat_y=lat_y,
                         crs = CRS("+proj=utm +zone=21K +south +datum=WGS84 +units=m +no_defs"))
#'
#'

#' ###   FOREST PARAGUAY 
							   
#' 10) Forest Paraguay   
FPytrk <- trk.convert(data = FPy,
                      .x=utm_x,
                      .y=utm_y,
                      .t=date,
                      id=id,
                      project_region=project_region,
                      sex=sex,
                      age=age,
                      weight=weight, 
                      status=status,
                      period=period,
                      long_x=long_x,
                      lat_y=lat_y,
                      crs = CRS("+proj=utm +zone=21J +south +datum=WGS84 +units=m +no_defs"))

#'
#'   

#' ### IGUAZU
#'	   
#' 11) Iguazu1
Iguazu1trk <- trk.convert(data = Iguazu1,
                      .x=utm_x,
                      .y=utm_y,
                      .t=date,
                      id=id,
                      project_region=project_region,
                      sex=sex,
                      age=age,
                      weight=weight, 
                      status=status,
                      period=period,
                      long_x=long_x,
                      lat_y=lat_y,
                      crs = CRS("+proj=utm +zone=21J +south +datum=WGS84 +units=m +no_defs"))

#'
#' 12) Iguazu2
Iguazu2trk <- trk.convert(data = Iguazu2,
                          .x=utm_x,
                          .y=utm_y,
                          .t=date,
                          id=id,
                          project_region=project_region,
                          sex=sex,
                          age=age,
                          weight=weight, 
                          status=status,
                          period=period,
                          long_x=long_x,
                          lat_y=lat_y,
                          crs = CRS("+proj=utm +zone=22J +south +datum=WGS84 +units=m +no_defs"))
#'
#'  Iguazutrk   
Iguazutrk=rbind(Iguazu1trk,Iguazu2trk)
#' 
#' 

#' ###   AMAZONIA   
#' 13) Flooded  Amazonia, Mamiraua (Brazil)   
Mamirauatrk <- trk.convert(data = Mamiraua,
                          .x=utm_x,
                          .y=utm_y,
                          .t=date,
                          id=id,
                          project_region=project_region,
                          sex=sex,
                          age=age,
                          weight=weight, 
                          status=status,
                          period=period,
                          long_x=long_x,
                          lat_y=lat_y,
                          crs = CRS("+proj=utm +zone=20M +south +datum=WGS84 +units=m +no_defs"))

 
#'
#'
#' 14   Dry/ East Amazonia, IOP PA, translocated
iopPAtrk <- trk.convert(data = iopPA,
                           .x=utm_x,
                           .y=utm_y,
                           .t=date,
                           id=id,
                           project_region=project_region,
                           sex=sex,
                           age=age,
                           weight=weight, 
                           status=status,
                           period=period,
                           long_x=long_x,
                           lat_y=lat_y,
                           crs = CRS("+proj=utm +zone=22M +south +datum=WGS84 +units=m +no_defs"))

#' 
#' 
#' ###   MEXICO
#' 
#' Greater Lacandona
#' 15) Lacandona
Lacandonatrk <- trk.convert(data = Lacandona,
                        .x=utm_x,
                        .y=utm_y,
                        .t=date,
                        id=id,
                        project_region=project_region,
                        sex=sex,
                        age=age,
                        weight=weight, 
                        status=status,
                        period=period,
                        long_x=long_x,
                        lat_y=lat_y,
                        crs = CRS("+proj=utm +zone=15Q +south +datum=WGS84 +units=m +no_defs"))

#'
#'
#' 16) MexEast
MexEasttrk <- trk.convert(data = MexEast,
                            .x=utm_x,
                            .y=utm_y,
                            .t=date,
                            id=id,
                            project_region=project_region,
                            sex=sex,
                            age=age,
                            weight=weight, 
                            status=status,
                            period=period,
                            long_x=long_x,
                            lat_y=lat_y,
                            crs = CRS("+proj=utm +zone=16Q +south +datum=WGS84 +units=m +no_defs"))

#'
#'
#' 17)  Sonora
Sonoratrk <- trk.convert(data = Sonora,
                          .x=utm_x,
                          .y=utm_y,
                          .t=date,
                          id=id,
                          project_region=project_region,
                          sex=sex,
                          age=age,
                          weight=weight, 
                          status=status,
                          period=period,
                          long_x=long_x,
                          lat_y=lat_y,
                          crs = CRS("+proj=utm +zone=12R +south +datum=WGS84 +units=m +no_defs"))

#' 
#' 
#' ###   PANTANAL
#' 
#' 18) PantanalTotal Brazil&Paraguay  -  7 Projects in total, all in the same UTM zone
Pantanaltrk <- trk.convert(data = Pantanal,
                         .x=utm_x,
                         .y=utm_y,
                         .t=date,
                         id=id,
                         project_region=project_region,
                         sex=sex,
                         age=age,
                         weight=weight, 
                         status=status,
                         period=period,
                         long_x=long_x,
                         lat_y=lat_y,
                         crs = CRS("+proj=utm +zone=21K +south +datum=WGS84 +units=m +no_defs"))
#'  
#' Objects for Pantanal project regions
 Oncafaritrk=Pantanaltrk %>% filter(project_region == "Oncafari")
 Paraguaytrk=Pantanaltrk %>% filter(project_region == "Pantanal Paraguay")
 Panthera1trk=Pantanaltrk %>% filter(project_region == "Panthera1")
 Panthera2trk=Pantanaltrk %>% filter(project_region == "Panthera2")
 RioNegrotrk=Pantanaltrk %>% filter(project_region == "Rio Negro")
 SaoBentotrk=Pantanaltrk %>% filter(project_region == "Sao Bento")
 Taiamatrk=Pantanaltrk %>% filter(project_region == "Taiama")
 
#' 
#' 
#' ###    ALL  JAGUARS  trk =>     jaguartrk  
#'		   
#' All Project regions trk
jaguartrk=rbind(AFW1trk,AFW2trk,Caatingatrk,Cerrado1trk,Cerrado2trk,CRicatrk,Drychtrk, Hchtrk,FPytrk,Iguazutrk,
                Mamirauatrk,iopPAtrk,Lacandonatrk, MexEasttrk, Sonoratrk,Oncafaritrk,Paraguaytrk,Panthera1trk,
                Panthera2trk,RioNegrotrk,SaoBentotrk,Taiamatrk) 

#'
#'
#' Dataframe for each individual with adjusted timezones (to run if we need any specic individual)
X1=subset(Hch,id=='1')   ####### Hch
X2=subset(FPy,id=='2')   ######### FPy
X3=subset(Hch,id=='3')   ####### Hch
X4=subset(Hch,id=='4')   ####### Hch
X5=subset(Hch,id=='5')   ####### Hch
X6=subset(Hch,id=='6')   ####### Hch
X7=subset(Hch,id=='7')   ####### Hch
X8=subset(FPy,id=='8')   ######### FPy
X9=subset(Hch,id=='9')   ####### Hch
X10=subset(Hch,id=='10') ####### Hch
X11=subset(Hch,id=='11') ####### Hch
X12=subset(Pantanal,id=='12') ########## Pantanal
X13=subset(Pantanal,id=='13') ########## Pantanal
X14=subset(Pantanal,id=='14') ########## Pantanal
X15=subset(Pantanal,id=='15') ########## Pantanal
X16=subset(Drych1,id=='16') ######### Drych1
X17=subset(Cerrado1,id=='17') ############### Cerrado1
X18=subset(Pantanal,id=='18') ########## Pantanal
X19=subset(Pantanal,id=='19') ########## Pantanal
X20=subset(Caatinga,id=='20') ################# Caatinga 
X21=subset(FPy,id=='21')  ######### FPy
X22=subset(Pantanal,id=='22') ########## Pantanal
X23=subset(Pantanal,id=='23') ########## Pantanal
X24=subset(iopPA,id=='24') ###### iopPA
X25=subset(Pantanal,id=='25') ########## Pantanal
X26=subset(CRica,id=='26')  ######### CRica
X27=subset(Pantanal,id=='27') ########## Pantanal
X28=subset(Pantanal,id=='28') ########## Pantanal
X29=subset(Pantanal,id=='29') ########## Pantanal
X30=subset(Pantanal,id=='30') ########## Pantanal
X31=subset(Pantanal,id=='31') ########## Pantanal
X32=subset(Pantanal,id=='32') ########## Pantanal
X33=subset(Pantanal,id=='33') ########## Pantanal
X34=subset(AFW1,id=='34')   ############### AFW1
X35=subset(AFW1,id=='35')   ############### AFW1
X36=subset(AFW1,id=='36')   ############### AFW1
X37=subset(AFW1,id=='37')   ############### AFW1
X38=subset(AFW1,id=='38')   ############### AFW1
X39=subset(AFW2,id=='39')   ###############  AFW2
X40=subset(AFW2,id=='40')   ###############  AFW2
X41=subset(Pantanal,id=='41') ########## Pantanal
X42=subset(Iguazu1,id=='42') ######## Iguazu1
X43=subset(Sonora,id=='43') ######## Sonora
X44=subset(Lacandona,id=='44') ######## Lacandona
X45=subset(Lacandona,id=='45') ######## Lacandona
X46=subset(Lacandona,id=='46')  ######## Lacandona
X47=subset(Lacandona,id=='47')  ######## Lacandona
X48=subset(Lacandona,id=='48')  ######## Lacandona
X49=subset(MexEast,id=='49')  ######### MexEast
X50=subset(Caatinga,id=='50')  ############### Caatinga
X51=subset(Pantanal,id=='51') ########## Pantanal
X52=subset(Pantanal,id=='52') ########## Pantanal
X53=subset(Pantanal,id=='53') ########## Pantanal
X54=subset(Pantanal,id=='54') ########## Pantanal
X55=subset(Pantanal,id=='55') ########## Pantanal
X56=subset(Pantanal,id=='56') ########## Pantanal
X57=subset(Pantanal,id=='57') ########## Pantanal
X58=subset(AFW1,id=='58')   ###############  AFW1
X59=subset(Pantanal,id=='59') ########## Pantanal
X60=subset(Pantanal,id=='60') ########## Pantanal
X61=subset(Pantanal,id=='61') ########## Pantanal
X62=subset(AFW1,id=='62')   ###############  AFW1
X63=subset(AFW2,id=='63')   ###############  AFW2
X64=subset(Sonora,id=='64') ######## Sonora
X65=subset(Cerrado1,id=='65')  ########## Cerrado1
X66=subset(Iguazu1,id=='66')  ########## Iguazu1
X67=subset(Cerrado1,id=='67')  ########## Cerrado1
X68=subset(Pantanal,id=='68') ########## Pantanal
X69=subset(Pantanal,id=='69') ########## Pantanal
X70=subset(Drych1,id=='70')  ######## Drych1
X71=subset(Drych2,id=='71') ####### Drych2
X72=subset(Drych2,id=='72') ####### Drych2
X73=subset(Drych2,id=='73') ####### Drych2
X74=subset(Pantanal,id=='74')  ########## Pantanal
X75=subset(Pantanal,id=='75')  ########## Pantanal
X76=subset(Drych1,id=='76') ####### Drych1
X77=subset(Drych1,id=='77') ####### Drych1
X78=subset(FPy,id=='78')  ####### FPy
X79=subset(Pantanal,id=='79') ########## Pantanal
X80=subset(Iguazu1,id=='80') ######## Iguazu1
X81=subset(Pantanal,id=='81') ########## Pantanal
X82=subset(Cerrado1,id=='82')  ########## Cerrado1
X83=subset(Iguazu2,id=='83')  ########## Iguazu2
X84=subset(Pantanal,id=='84')  ########## Pantanal
X85=subset(Cerrado1,id=='85')  ########## Cerrado1
X86=subset(Pantanal,id=='86') ########## Pantanal
X87=subset(Pantanal,id=='87') ########## Pantanal
X88=subset(Pantanal,id=='88') ########## Pantanal
X89=subset(Cerrado2,id=='89') ######### Cerrado2
X90=subset(Iguazu1,id=='90') ######### Iguazu1
X91=subset(Pantanal,id=='91') ########## Pantanal
X92=subset(Pantanal,id=='92') ########## Pantanal
X93=subset(Mamiraua,id=='93') ######### Mamiraua
X94=subset(Mamiraua,id=='94') ######### Mamiraua
X95=subset(Mamiraua,id=='95') ######### Mamiraua
X96=subset(Mamiraua,id=='96') ######### Mamiraua
X97=subset(Mamiraua,id=='97') ######### Mamiraua
X98=subset(Mamiraua,id=='98') ######### Mamiraua
X99=subset(Mamiraua,id=='99') ######### Mamiraua
X100=subset(Mamiraua,id=='100')######### Mamiraua
X101=subset(Pantanal,id=='101') ########## Pantanal
X102=subset(Pantanal,id=='102') ########## Pantanal
X103=subset(Pantanal,id=='103') ########## Pantanal
X104=subset(Pantanal,id=='104') ########## Pantanal
X105=subset(Pantanal,id=='105') ########## Pantanal
X106=subset(Pantanal,id=='106') ########## Pantanal
X107=subset(Pantanal,id=='107')########## Pantanal
X108=subset(Pantanal,id=='108')########## Pantanal
X109=subset(Pantanal,id=='109')########## Pantanal
X110=subset(Pantanal,id=='110')########## Pantanal
X111=subset(Pantanal,id=='111')########## Pantanal
X112=subset(Pantanal,id=='112')########## Pantanal
X113=subset(Pantanal,id=='113')########## Pantanal
X114=subset(Pantanal,id=='114')########## Pantanal
X115=subset(Pantanal,id=='115')########## Pantanal
X116=subset(Pantanal,id=='116')########## Pantanal
X117=subset(Pantanal,id=='117')########## Pantanal

#'
#' #### Produce an Rmd and html outputs using ezknitr
ezspin(file = "JaguarDataPrep.R", out_dir = "reports",
       params = list("DATASET_NAME" = "jaguar.dat"), 
       keep_html = TRUE, keep_rmd = TRUE)

open_output_dir()
#' Other info
sessionInfo()	  
proc.time()


 

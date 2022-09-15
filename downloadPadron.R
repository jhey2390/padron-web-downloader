library(tidyverse)
library(rvest)
rm(list = ls())
back <- getwd()
unlink("Padron_web.dbf")
url <- "http://escale.minedu.gob.pe/uee/-/document_library_display/GMv7/view/958881"
page <- rvest::read_html(url) # load the website
table <- rvest::html_nodes(page,"table") # extract table from the website

nurl<-(table%>%html_children())%>%tail(1)%>%html_element("a")%>% html_attr('href') # find the url to next page
page2 <- rvest::read_html(nurl) # load the next page
durl <- page2%>% html_element(css = "a#_110_INSTANCE_GMv7_gezi")%>%html_attr("href") # find the url to download Padron file
date <- as.Date(substr(durl,nchar(durl)-11,nchar(durl)-4),format="%Y%m%d") # save the update date
temp <- tempfile(fileext = ".zip") # create temporal file

options(timeout = 240)
download.file(durl,temp,timeout = 1) # download Padron file and to save in temporary file
temp2 <- utils::unzip(zipfile = temp,files = "Padron_web.dbf")
padron<-foreign::read.dbf(temp2,as.is = T) #unpack 
unlink(temp)

qp_before <- c("\xa0","\x82","\xa1","\xa2","\xa3","\xa4","\xa5","\xb5","\x90","\xd6","\xe0","\xe9")
qp_after <- c("á","é","í","ó","ú","ñ","Ñ","Á","É","Í","Ó","Ú")

vars <- c(4,6,7,9,11,13,15,16,20,22,25,30,31,32,34,40)

padron <- padron %>%
  mutate_at(vars,~gsub("\xc3í","á",stringi::stri_replace_all_fixed(str = .x,
                                                                   pattern =  qp_before,
                                                                   replacement =  qp_after,
                                                                   vectorise_all = F,
                                                                   vectorize_all = F,
                                                                   case_insensitive = F)))

print(list("comment" = "Fecha de Padrón","date" = date))
setwd(back)
unlink("Padron_web.dbf")
rm(list = ls()[which(!ls() %in% c("date","padron"))])



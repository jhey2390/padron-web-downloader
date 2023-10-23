library(tidyverse)
library(rvest)
library(stringi)

#rm(list = ls())
memory = ls()
back <- getwd()
setwd('D:/ADLER/00 BASES GENERALES/DescargaPadronWeb')
url <- "http://escale.minedu.gob.pe/uee/-/document_library_display/GMv7/view/958881"
page <- rvest::read_html(url,Encoding('utf-8')) # load the website
if(file.exists('PadronWeb.RData'))
{
  load('PadronWeb.RData')
  dateWeb = (((rvest::html_nodes(page,"table")) %>% tail(1)) %>% html_children()) %>%
    tail(1) %>% html_text %>% str_extract('[0-9]{8,8}') %>%
    as.Date(format = '%Y%m%d')
}
if(!file.exists('PadronWeb.RData')|(dateWeb != date)){

  table <- rvest::html_nodes(page,"table") # extract table from the website
  nurl<-(table%>%html_children())%>%tail(1)%>%html_element("a")%>% html_attr('href') # find the url to next page
  page2 <- rvest::read_html(nurl) # load the next page
  durl <- page2%>% html_element(css = "a#_110_INSTANCE_GMv7_gezi")%>%html_attr("href") # find the url to download Padron file
  date <- as.Date(substr(durl,nchar(durl)-11,nchar(durl)-4),format="%Y%m%d") # save the update date
  temp <- tempfile(fileext = ".zip") # create temporal file

  options(timeout = 240)
  download.file(durl,temp,timeout = 1) # download Padron file and to save in temporary file
  temp2 <- utils::unzip(zipfile = temp,files = "Padron_web.dbf")
  shell('py load.py')
  padron = readr::read_delim('PadronWeb.txt',delim = '|')
  unlink(temp)

  padron
  #qp_before <- c("\xa0","\x82","\xa1","\xa2","\xa3","\xa4","\xa5","\xb5","\x90","\xd6","\xe0","\xe9","\xc3Ü","\x9a")
  #qp_after <- c("á","é","í","ó","ú","ñ","Ñ","Á","É","Í","Ó","Ú","Ú",'Ü')
#
  #vars <- c(4,6,7,9,11,13,15,16,20,22,25,30,31,32,34,40)
#
  #padron <- padron %>%
  #  mutate_at(vars,~gsub("\xc3Ü","Ú",gsub("\xc3í","á",stringi::stri_replace_all_fixed(str = .x,
  #                                                                   pattern =  qp_before,
  #                                                                   replacement =  qp_after,
  #                                                                   vectorise_all = F,
  #                                                                   vectorize_all = F,
  #                                                                   case_insensitive = F))))
  save(list = c('padron','date'),file = 'PadronWeb.RData')
  unlink("Padron_web.dbf")
  write.table(x = padron %>%
                select(-c(16:21)),file = 'PadronWeb.txt',sep = '|',fileEncoding = 'utf-8')
}
setwd(back)
rm(list = ls()[which(!ls() %in% c(memory,"date","padron"))])
print(list("comment" = "Fecha de Padrón","date" = date))



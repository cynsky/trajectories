require(XML); library(sp); library(spacetime); library(trajectories)
extract.track=function(year = 2012, p = TRUE) {
# based on # ARTHUR CHARPENTIER # http://freakonometrics.hypotheses.org/17113
	loc <- paste("http://weather.unisys.com/hurricane/atlantic/",year,"/index.php",sep="")
	tabs <- readHTMLTable(htmlParse(loc)) 
	storms <- unlist(strsplit(as.character(tabs[[1]]$Name),split=" "))
	index <- storms %in% c("Tropical","Storm", paste("Hurricane-",1:6,sep=""),
		"Depression","Subtropical","Extratropical","Low",
		paste("Storm-",1:6,sep=""), "Xxx")
	nstorms  <- storms[!index]
	tracks = list()
	for(i in length(nstorms):1) {
		loc=paste("http://weather.unisys.com/hurricane/atlantic/",
			year, "/", nstorms[i], "/track.dat", sep="")
		track=read.fwf(loc, skip=3, widths = c(4,6,8,12,4,6,20))
		names(track)=c("ADV", "LAT", "LON", "TIME", "WIND", "PR", "STAT")
		track$LAT=as.numeric(as.character(track$LAT))
		track$LON=as.numeric(as.character(track$LON))
		track$WIND=as.numeric(as.character(track$WIND))
		track$PR=as.numeric(as.character(track$PR))
		track$year=year
		pts = SpatialPoints(cbind(track$LON, track$LAT), CRS("+proj=longlat +datum=WGS84"))
		time = as.POSIXct(paste(year, track$TIME, sep="/"), format="%Y/ %m/%d/%HZ  ",tz="UTC")
		tr = Track(STIDF(pts, time, track))
		tracks[nstorms[i]] = tr
		if (p==TRUE)
			cat(year,i,nstorms[i],nrow(track),"\n")
	}
	return(Tracks(tracks))
}
#m=extract.track(2012)
#m=extract.track(2011:2012)
TOTTRACK=list()
#for(y in 2012:1851)
for(y in 2012:2009)
	#TOTTRACK=rbind(TOTTRACK, extract.track(y))
	# http://robertgrantstats.wordpress.com/2014/10/01/transparent-hurricane-paths-in-r/
	if (!inherits(try(x <- extract.track(y)), "try-error"))
		TOTTRACK[as.character(y)] = x

trColl = TracksCollection(TOTTRACK)

library(maps)
map("world",xlim=c(-80,-40),ylim=c(10,50),col="light yellow",fill=TRUE)
for(n in unique(TOTTRACK$name))
	#lines(TOTTRACK$LON[TOTTRACK$name==n],TOTTRACK$LAT[TOTTRACK$name==n],lwd=.5,col="red")
	lines(TOTTRACK$LON[TOTTRACK$name==n],TOTTRACK$LAT[TOTTRACK$name==n],lwd=.5,
		col=rgb(255,0,0,18,maxColorValue=255))

library(ks)
U=TOTTRACK[,c("LON","LAT")]
U=U[!is.na(U$LON),]
H=diag(c(.2,.2))
fat=kde(U,H,xmin=c(min(U[,1]),min(U[,2])),xmax=c(max(U[,1]),max(U[,2])))
z=fat$estimate
image(z)
map("world",add=TRUE)

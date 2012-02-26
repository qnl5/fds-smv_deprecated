MODULE ISOSMOKE
  USE PRECISION_PARAMETERS
  USE MEMORY_FUNCTIONS, ONLY: ChkMemErr

  IMPLICIT NONE

  CHARACTER(255), PARAMETER :: smvvid='$Id: smvv.f90 10041 2012-02-10 13:43:13Z mcgratta $'
  CHARACTER(255), PARAMETER :: smvvrev='$Revision: 10041 $'
  CHARACTER(255), PARAMETER :: smvvdate='$Date: 2012-02-10 08:43:13 -0500 (Fri, 10 Feb 2012) $'

  PRIVATE
  PUBLIC ISO_TO_FILE,SMOKE3D_TO_FILE,GET_REV_smvv

CONTAINS

! ------------------ GET_REV_smvv ------------------------

SUBROUTINE GET_REV_smvv(MODULE_REV,MODULE_DATE)
INTEGER,INTENT(INOUT) :: MODULE_REV
CHARACTER(255),INTENT(INOUT) :: MODULE_DATE

WRITE(MODULE_DATE,'(A)') smvvrev(INDEX(smvvrev,':')+2:LEN_TRIM(smvvrev)-2)
READ (MODULE_DATE,'(I5)') MODULE_REV
WRITE(MODULE_DATE,'(A)') smvvdate

END SUBROUTINE GET_REV_smvv

! ------------------ ISO_TO_FILE ------------------------

SUBROUTINE ISO_TO_FILE(LU_ISO,T,VDATA,HAVE_TDATA,TDATA,HAVE_IBLANK,IBLANK,&
           LEVELS, NLEVELS, XPLT, NX, YPLT, NY, ZPLT, NZ)
           
  INTEGER, INTENT(INOUT) :: LU_ISO
  REAL(FB), INTENT(IN) :: T
  INTEGER, INTENT(IN) :: HAVE_TDATA, HAVE_IBLANK
  REAL(FB), INTENT(IN), DIMENSION(NX,NY,NZ) :: VDATA,TDATA
  INTEGER, INTENT(IN), DIMENSION(NX-1,NY-1,NZ-1) :: IBLANK
  INTEGER, INTENT(IN) :: NLEVELS
  REAL(FB), INTENT(IN), DIMENSION(NLEVELS) :: LEVELS
  INTEGER, INTENT(IN) :: NX, NY, NZ
  REAL(FB), INTENT(IN), DIMENSION(NX) :: XPLT
  REAL(FB), INTENT(IN), DIMENSION(NY) :: YPLT
  REAL(FB), INTENT(IN), DIMENSION(NZ) :: ZPLT
           
  INTEGER :: I
  INTEGER :: NXYZVERTS, NTRIANGLES, NXYZVERTS_ALL, NTRIANGLES_ALL
  REAL(FB), DIMENSION(:), POINTER :: XYZVERTS
  INTEGER, DIMENSION(:), POINTER :: TRIANGLES, SURFACES
  REAL(FB), DIMENSION(:), POINTER :: XYZVERTS_ALL
  INTEGER, DIMENSION(:), POINTER :: TRIANGLES_ALL, SURFACES_ALL
  INTEGER :: MEMERR
  
  NXYZVERTS_ALL=0
  NTRIANGLES_ALL=0
  NULLIFY(XYZVERTS)
  NULLIFY(TRIANGLES)
  NULLIFY(SURFACES)
  NULLIFY(XYZVERTS_ALL)
  NULLIFY(TRIANGLES_ALL)
  NULLIFY(SURFACES_ALL)
  
  DO I =1, NLEVELS
    CALL ISO_TO_GEOM(VDATA, HAVE_TDATA, TDATA, HAVE_IBLANK, IBLANK, LEVELS(I), &
          XPLT, NX, YPLT, NY, ZPLT, NZ,XYZVERTS, NXYZVERTS, TRIANGLES, NTRIANGLES)
    IF (NTRIANGLES>0.AND.NXYZVERTS>0) THEN
      ALLOCATE(SURFACES(NTRIANGLES),STAT=MEMERR)
      CALL ChkMemErr('ISO_TO_FILE','SURFACES',MEMERR)
      SURFACES=I
      CALL MERGE_GEOM(TRIANGLES_ALL,SURFACES_ALL,NTRIANGLES_ALL,XYZVERTS_ALL,NXYZVERTS_ALL,&
           TRIANGLES,SURFACES,NTRIANGLES,XYZVERTS,NXYZVERTS)
      DEALLOCATE(SURFACES)
      DEALLOCATE(XYZVERTS) ! these variables were allocated in ISO_TO_GEOM
      DEALLOCATE(TRIANGLES)
    ENDIF
  END DO
  IF (NXYZVERTS_ALL>0.AND.NTRIANGLES_ALL>0) THEN
    CALL REMOVE_DUP_VERTS(XYZVERTS_ALL,NXYZVERTS_ALL,TRIANGLES_ALL,NTRIANGLES_ALL)
    CALL REDUCE_TRIANGLES(XYZVERTS_ALL,NXYZVERTS_ALL,TRIANGLES_ALL,SURFACES_ALL,NTRIANGLES_ALL,XPLT,NX,YPLT,NY,ZPLT,NZ)
  ENDIF
  IF (LU_ISO<0) THEN
    LU_ISO=-LU_ISO
    CALL ISO_HEADER_OUT(LU_ISO,LEVELS,NLEVELS)
  ENDIF
  CALL ISO_OUT(LU_ISO,T,XYZVERTS_ALL,NXYZVERTS_ALL,TRIANGLES_ALL,SURFACES_ALL,NTRIANGLES_ALL)
  IF (NXYZVERTS_ALL>0.AND.NTRIANGLES>0) THEN
    DEALLOCATE(XYZVERTS_ALL)
    DEALLOCATE(SURFACES_ALL)
    DEALLOCATE(TRIANGLES_ALL)
  ENDIF

  RETURN
END SUBROUTINE ISO_TO_FILE

! ------------------ COMPARE_VEC3 ------------------------

INTEGER FUNCTION COMPARE_VEC3(XI,XJ)
REAL(FB), INTENT(IN), DIMENSION(3) :: XI, XJ

REAL(FB) :: DELTA=0.0001

IF (XI(1)<XJ(1)-DELTA) THEN
  COMPARE_VEC3 = -1
  RETURN
ENDIF
IF (XI(1)>XJ(1)+DELTA) THEN
  COMPARE_VEC3 = 1
  RETURN
ENDIF
IF (XI(2)<XJ(2)-DELTA) THEN
  COMPARE_VEC3 = -1
  RETURN
ENDIF
IF (XI(2)>XJ(2)+DELTA) THEN
  COMPARE_VEC3 = 1
  RETURN
ENDIF
IF (XI(3)<XJ(3)-DELTA) THEN
  COMPARE_VEC3 = -1
  RETURN
ENDIF
IF (XI(3)>XJ(3)+DELTA) THEN
  COMPARE_VEC3 = 1
  RETURN
ENDIF
COMPARE_VEC3 = 0
RETURN
END FUNCTION COMPARE_VEC3

! ------------------ GET_IDNEX ------------------------

INTEGER FUNCTION GET_INDEX(X,ARRAY, NARRAY)
REAL(FB), INTENT(IN) :: X
REAL(FB), INTENT(IN), DIMENSION(NARRAY) :: ARRAY
INTEGER, INTENT(IN) :: NARRAY

REAL(FB) :: DX

DX = (ARRAY(NARRAY)-ARRAY(1))/REAL(NARRAY-1)
GET_INDEX = -1

IF (X.LT.ARRAY(1)-DX/2.0.OR.X.GT.ARRAY(NARRAY)+DX/2.0)RETURN

GET_INDEX = (X-ARRAY(1))/DX + 0.5

IF (GET_INDEX.LT.0)GET_INDEX=0
IF (GET_INDEX.GT.NARRAY-1)GET_INDEX=NARRAY-1

RETURN
END FUNCTION GET_INDEX

! ------------------ GET_NODE_INDEX ------------------------

INTEGER FUNCTION GET_NODE_INDEX(XYZ,XPLT,NX,YPLT,NY,ZPLT,NZ)
REAL, INTENT(IN), DIMENSION(3) :: XYZ
REAL, INTENT(IN), DIMENSION(NX) :: XPLT
REAL, INTENT(IN), DIMENSION(NY) :: YPLT 
REAL, INTENT(IN), DIMENSION(NZ) :: ZPLT
INTEGER, INTENT(IN) :: NX, NY, NZ

INTEGER :: INODE, JNODE, KNODE

GET_NODE_INDEX=-1

INODE = GET_INDEX(XYZ(1),XPLT,NX)
IF (INODE.EQ.-1)RETURN

JNODE = GET_INDEX(XYZ(2),YPLT,NY)
IF (JNODE.EQ.-1)RETURN

KNODE = GET_INDEX(XYZ(3),ZPLT,NZ)
IF (KNODE.EQ.-1)RETURN

GET_NODE_INDEX = INODE + JNODE*NX + KNODE*NX*NY
RETURN

END FUNCTION GET_NODE_INDEX

! ------------------ REDUCE_TRIANGLES ------------------------

SUBROUTINE REDUCE_TRIANGLES(VERTS,NVERTS,TRIANGLES,SURFACES,NTRIANGLES,XPLT,NX,YPLT,NY,ZPLT,NZ)
REAL(FB), INTENT(IN), POINTER, DIMENSION(:)  :: VERTS
INTEGER, INTENT(IN), POINTER, DIMENSION(:) :: TRIANGLES
INTEGER, INTENT(IN), POINTER, DIMENSION(:) :: SURFACES
INTEGER, INTENT(INOUT) :: NTRIANGLES
INTEGER, INTENT(INOUT) :: NVERTS 
REAL, INTENT(IN), DIMENSION(NX) :: XPLT
REAL, INTENT(IN), DIMENSION(NY) :: YPLT
REAL, INTENT(IN), DIMENSION(NZ) :: ZPLT
INTEGER, INTENT(IN) :: NX, NY, NZ

INTEGER :: I,J
REAL(FB) :: EPS=0.0001
REAL(FB) :: DX,DXI,DY,DYI,DZ,DZI
REAL(FB), DIMENSION(3) :: XYZ(3)
INTEGER, DIMENSION(1:3) :: NODES,IS,IE
INTEGER, DIMENSION(:), ALLOCATABLE :: CLOSEST_NODES, TRIANGLE_REMOVE
INTEGER :: I1, I2, I3
INTEGER :: IFROM, ITO
REAL(FB) SUM
REAL(FB), DIMENSION(3) :: FACTORS

ALLOCATE(CLOSEST_NODES(NVERTS))
ALLOCATE(TRIANGLE_REMOVE(NTRIANGLES))

CLOSEST_NODES=-2
TRIANGLE_REMOVE=0

DO I = 1, NTRIANGLES
  NODES(1:3) = 1 + TRIANGLES(3*I-2:3*I)
  DO J = 1, 3
    IF (CLOSEST_NODES(NODES(J)).EQ.-2) THEN
      XYZ(1:3) = VERTS(3*NODES(J)-2:3*NODES(J))
      CLOSEST_NODES(NODES(J))=GET_NODE_INDEX(XYZ(1:3),XPLT,NX,YPLT,NY,ZPLT,NZ)
    ENDIF
  END DO
  I1 = CLOSEST_NODES(NODES(1))
  I2 = CLOSEST_NODES(NODES(2))
  I3 = CLOSEST_NODES(NODES(3))
  IF (I1.NE.-1.AND.I1.EQ.I2.AND.I1.EQ.I3) THEN        ! 1 1 1
    FACTORS(1:3) = 1.0
    TRIANGLES(3*I-1)=TRIANGLES(3*I-2)
    TRIANGLES(3*I)=TRIANGLES(3*I-2)
  ELSE IF (I1.NE.-1.AND.I1.EQ.I2.AND.I1.NE.I3) THEN   ! 1 1 2
    FACTORS(1:2) = 1.0
    FACTORS(3) = 0.0
    TRIANGLES(3*I-1)=TRIANGLES(3*I-2)
  ELSE IF (I1.NE.-1.AND.I1.EQ.I3.AND.I1.NE.I2) THEN   ! 1 2 1
    FACTORS(1) = 1.0
    FACTORS(2) = 0.0
    FACTORS(3) = 1.0
    TRIANGLES(3*I)=TRIANGLES(3*I-2)
  ELSE IF (I2.NE.-1.AND.I2.EQ.I3.AND.I1.NE.I2) THEN   ! 2 1 1
    FACTORS(1) = 0.0
    FACTORS(2:3) = 1
    TRIANGLES(3*I)=TRIANGLES(3*I-1)
  ELSE                                                ! 1 2 3
    FACTORS(1:3) = 0.0
  ENDIF
  SUM = FACTORS(1) + FACTORS(2) + FACTORS(3)
  IS(1:3) = 3*NODES(1:3)-2
  IE(1:3) = 3*NODES(1:3)
  IF (SUM>0) THEN
    TRIANGLE_REMOVE(I)=1
    XYZ(1:3) = (FACTORS(1)*VERTS(IS(1):IE(1))+FACTORS(2)*VERTS(IS(2):IE(2))+FACTORS(3)*VERTS(IS(3):IE(3)))/SUM
    I1 = GET_NODE_INDEX(XYZ(1:3),XPLT,NX,YPLT,NY,ZPLT,NZ)
    IF (FACTORS(1)>0.0) THEN
      VERTS(IS(1):IE(1))=XYZ(1:3)
      CLOSEST_NODES(NODES(1))=I1
    ENDIF
    IF (FACTORS(2)>0.0) THEN
      VERTS(IS(2):IE(2))=XYZ(1:3)
      CLOSEST_NODES(NODES(2))=I1
    ENDIF
    IF (FACTORS(3)>0.0) THEN
      VERTS(IS(3):IE(3))=XYZ(1:3)
      CLOSEST_NODES(NODES(3))=I1
    ENDIF
  ENDIF
END DO
CALL REMOVE_DUP_VERTS(VERTS,NVERTS,TRIANGLES,NTRIANGLES)
ITO=1
DO IFROM = 1, NTRIANGLES
  IF (TRIANGLE_REMOVE(IFROM).EQ.1)CYCLE
  NODES(1:3) = TRIANGLES(3*IFROM-2:3*IFROM)
  IF (NODES(1).EQ.NODES(2).OR.NODES(1).EQ.NODES(3).OR.NODES(2).EQ.NODES(3))CYCLE
  TRIANGLES(3*ITO-2:3*ITO)=TRIANGLES(3*IFROM-2:3*IFROM)
  SURFACES(ITO)=SURFACES(IFROM)
  ITO = ITO + 1
END DO
NTRIANGLES=ITO-1

DEALLOCATE(CLOSEST_NODES)
DEALLOCATE(TRIANGLE_REMOVE)
END SUBROUTINE  REDUCE_TRIANGLES

! ------------------ REMOVE_DUP_VERTS ------------------------

SUBROUTINE REMOVE_DUP_VERTS(VERTS,NVERTS,TRIANGLES,NTRIANGLES)

REAL(FB), INTENT(IN), POINTER, DIMENSION(:)  :: VERTS
INTEGER, INTENT(IN), POINTER, DIMENSION(:) :: TRIANGLES
INTEGER, INTENT(IN) :: NTRIANGLES
INTEGER, INTENT(INOUT) :: NVERTS 

INTEGER, ALLOCATABLE, DIMENSION(:) :: MAPVERTS
INTEGER :: I,DOIT,NVERTS_OLD,IFROM,ITO
INTEGER :: MEMERR

NVERTS_OLD = NVERTS

IF (NVERTS.EQ.0.OR.NTRIANGLES.EQ.0)RETURN
ALLOCATE(MAPVERTS(NVERTS),STAT=MEMERR)
CALL ChkMemErr('REDUCE_DUP_VERTS','MAPVERTS',MEMERR)

MAPVERTS(1)=1
ITO=1
DO IFROM=2, NVERTS
  DOIT=1
  DO I = 1, ITO
    IF (COMPARE_VEC3(VERTS(3*IFROM-2:3*IFROM),VERTS(3*I-2:3*I)).EQ.0) THEN
      DOIT=0
      MAPVERTS(IFROM)=I
      EXIT
    ENDIF
  END DO
  IF (DOIT==0)CYCLE
  ITO = ITO + 1
  MAPVERTS(IFROM)=ITO
  VERTS(3*ITO-2:3*ITO)=VERTS(3*IFROM-2:3*IFROM)
END DO
NVERTS=ITO
    
! MAP TRIANGLE NODES TO NEW NODES

DO I=1,3*NTRIANGLES
  TRIANGLES(I) = MAPVERTS(TRIANGLES(I) + 1) - 1
END DO

DEALLOCATE(MAPVERTS)

END SUBROUTINE REMOVE_DUP_VERTS

! ------------------ FGETOSPSURFACE ------------------------

SUBROUTINE ISO_TO_GEOM(VDATA, HAVE_TDATA, TDATA, HAVE_IBLANK, IBLANK_CELL, LEVEL, &
     XPLT, NX, YPLT, NY, ZPLT, NZ,&
     XYZVERTS, NXYZVERTS, TRIANGLES, NTRIANGLES)

  INTEGER, INTENT(IN) :: NX, NY, NZ
  INTEGER, INTENT(IN) :: HAVE_TDATA, HAVE_IBLANK
  REAL(FB), DIMENSION(NX,NY,NZ), INTENT(IN) :: VDATA, TDATA
  INTEGER, DIMENSION(NX-1,NY-1,NZ-1), INTENT(IN) :: IBLANK_CELL
  REAL(FB), INTENT(IN) :: LEVEL
  REAL(FB), INTENT(IN), DIMENSION(NX) :: XPLT
  REAL(FB), INTENT(IN), DIMENSION(NY) :: YPLT
  REAL(FB), INTENT(IN), DIMENSION(NZ) :: ZPLT
     
  REAL(FB), INTENT(OUT), DIMENSION(:), POINTER :: XYZVERTS
  INTEGER, INTENT(OUT), DIMENSION(:), POINTER :: TRIANGLES
  INTEGER, INTENT(OUT) :: NTRIANGLES, NXYZVERTS
  
  REAL(FB), DIMENSION(0:1) :: XX, YY, ZZ
  REAL(FB), DIMENSION(0:7) :: VALS, TVALS
  REAL(FB), DIMENSION(0:35) :: XYZVERTS_LOCAL,TVAL_LOCAL
  INTEGER :: NXYZVERTS_LOCAL
  INTEGER, DIMENSION(0:14) :: TRIS_LOCAL
  INTEGER :: NTRIS_LOCAL
  INTEGER :: NXYZVERTS_MAX, NTRIANGLES_MAX
  REAL(FB) :: VMIN, VMAX
  
  INTEGER :: I, J, K
     
  INTEGER :: MEMERR
  
  NULLIFY(XYZVERTS)
  NULLIFY(TRIANGLES)
  NTRIANGLES=0
  NXYZVERTS=0
  NXYZVERTS_MAX=1000
  NTRIANGLES_MAX=1000
  ALLOCATE(XYZVERTS(3*NXYZVERTS_MAX),STAT=MEMERR)
  CALL ChkMemErr('ISO_TO_GEOM','XYZVERTS',MEMERR)
  ALLOCATE(TRIANGLES(3*NTRIANGLES_MAX),STAT=MEMERR)
  CALL ChkMemErr('ISO_TO_GEOM','TRIANGLES',MEMERR)
     
  DO I=1, NX-1
    XX(0)=XPLT(I)
    XX(1)=XPLT(I+1)
    DO J=1,NY-1
      YY(0)=YPLT(J);
      YY(1)=YPLT(J+1);
      DO K=1,NZ-1
        IF (HAVE_IBLANK == 1.AND.IBLANK_CELL(I,J,K) == 0)CYCLE
        
        VALS(0)=VDATA(  I,  J,  K)
        VALS(1)=VDATA(  I,J+1,  K)
        VALS(2)=VDATA(I+1,J+1,  K)
        VALS(3)=VDATA(I+1,  J,  K)
        VALS(4)=VDATA(  I,  J,K+1)
        VALS(5)=VDATA(  I,J+1,K+1)
        VALS(6)=VDATA(I+1,J+1,K+1)
        VALS(7)=VDATA(I+1,  J,K+1)

        VMIN=MIN(VALS(0),VALS(1),VALS(2),VALS(3),VALS(4),VALS(5),VALS(6),VALS(7))
        VMAX=MAX(VALS(0),VALS(1),VALS(2),VALS(3),VALS(4),VALS(5),VALS(6),VALS(7))
        IF (VMIN > LEVEL.OR.VMAX < LEVEL)CYCLE
           
        ZZ(0)=ZPLT(K);
        ZZ(1)=ZPLT(K+1);

        IF (HAVE_TDATA == 1) THEN
          TVALS(0)=TDATA(  I,  J,  K)
          TVALS(1)=TDATA(  I,J+1,  K)
          TVALS(2)=TDATA(I+1,J+1,  K)
          TVALS(3)=TDATA(I+1,  J,  K)
          TVALS(4)=TDATA(  I,  J,K+1)
          TVALS(5)=TDATA(  I,J+1,K+1)
          TVALS(6)=TDATA(I+1,J+1,K+1)
          TVALS(7)=TDATA(I+1,  J,K+1)
        ENDIF

        CALL FGETISOBOX(XX,YY,ZZ,VALS,HAVE_TDATA,TVALS,LEVEL,&
            XYZVERTS_LOCAL,TVAL_LOCAL,NXYZVERTS_LOCAL,TRIS_LOCAL,NTRIS_LOCAL)

        IF (NXYZVERTS_LOCAL > 0.OR.NTRIS_LOCAL > 0) THEN
          CALL UPDATEISOSURFACE(XYZVERTS_LOCAL, NXYZVERTS_LOCAL, TRIS_LOCAL, NTRIS_LOCAL, &
          XYZVERTS, NXYZVERTS, NXYZVERTS_MAX, TRIANGLES, NTRIANGLES, NTRIANGLES_MAX)
        ENDIF
      END DO
    END DO
  END DO
  RETURN     
END SUBROUTINE ISO_TO_GEOM


! ------------------ ISO_HEADER_OUT ------------------------

SUBROUTINE ISO_HEADER_OUT(LU_ISO,ISO_LEVELS,NISO_LEVELS)
  INTEGER, INTENT(IN) :: LU_ISO
  REAL(FB), INTENT(IN), DIMENSION(NISO_LEVELS) :: ISO_LEVELS
  INTEGER, INTENT(IN) :: NISO_LEVELS
  
  INTEGER :: VERSION=1
  INTEGER :: I
  INTEGER :: ONE=1,ZERO=0
  
  WRITE(LU_ISO) ONE
  WRITE(LU_ISO) VERSION
  WRITE(LU_ISO) NISO_LEVELS
  IF (NISO_LEVELS>0) WRITE(LU_ISO) (ISO_LEVELS(I),I=1,NISO_LEVELS)
  WRITE(LU_ISO) ZERO  ! no integer header
  WRITE(LU_ISO) ZERO, ZERO  ! no static nodes or triangles
  RETURN
END SUBROUTINE ISO_HEADER_OUT           

! ------------------ ISO_OUT ------------------------

SUBROUTINE ISO_OUT(LU_ISO,STIME,VERTS,NVERTS,TRIANGLES,SURFACES,NTRIANGLES)
  INTEGER, INTENT(INOUT) :: LU_ISO
  REAL(FB), INTENT(IN) :: STIME
  INTEGER, INTENT(IN) :: NVERTS,  NTRIANGLES
  REAL(FB), INTENT(IN), DIMENSION(:), POINTER :: VERTS
  INTEGER, INTENT(IN), DIMENSION(:), POINTER :: TRIANGLES
  INTEGER, INTENT(IN), DIMENSION(:), POINTER :: SURFACES
  
  INTEGER :: GEOM_TYPE=0
  
  INTEGER :: I
  
  WRITE(LU_ISO) STIME, GEOM_TYPE ! dynamic geometry (displayed only at time STIME)
  WRITE(LU_ISO) NVERTS,NTRIANGLES
  IF (NVERTS>0) WRITE(LU_ISO) (VERTS(I),I=1,3*NVERTS)
  IF (NTRIANGLES>0) THEN
    WRITE(LU_ISO) (1+TRIANGLES(I),I=1,3*NTRIANGLES)
    WRITE(LU_ISO) (SURFACES(I),I=1,NTRIANGLES)
  ENDIF

  RETURN
END SUBROUTINE ISO_OUT           

! ------------------ MERGE_GEOM ------------------------

SUBROUTINE MERGE_GEOM(TRIS1,SURFACES1,NTRIS1,NODES1,NNODES1,&
                     TRIS2,SURFACES2,NTRIS2,NODES2,NNODES2)

  INTEGER, INTENT(INOUT), DIMENSION(:), POINTER :: TRIS1, SURfACES1
  REAL(FB), INTENT(INOUT), DIMENSION(:), POINTER :: NODES1
  INTEGER, INTENT(INOUT) :: NTRIS1,NNODES1
  
  INTEGER, DIMENSION(:), POINTER :: TRIS2, SURFACES2
  REAL(FB), DIMENSION(:), POINTER :: NODES2
  INTEGER, INTENT(IN) :: NTRIS2,NNODES2
  
  INTEGER :: NNODES_NEW, NTRIS_NEW, N
  
  NNODES_NEW = NNODES1 + NNODES2
  NTRIS_NEW = NTRIS1 + NTRIS2
  
  CALL REALLOCATE_F('MERGE_GEOM','NODES1',NODES1,3*NNODES1,3*NNODES_NEW)
  CALL REALLOCATE_I('MERGE_GEOM','TRIS1',TRIS1,3*NTRIS1,3*NTRIS_NEW)
  CALL REALLOCATE_I('MERGE_GEOM','SURFACES1',SURFACES1,NTRIS1,NTRIS_NEW)
  
  NODES1(1+3*NNODES1:3*NNODES_NEW)=NODES2(1:3*NNODES2)
  TRIS1(1+3*NTRIS1:3*NTRIS_NEW)=TRIS2(1:3*NTRIS2)
  SURFACES1(1+NTRIS1:NTRIS_NEW)=SURFACES2(1:NTRIS2)
  
  DO N=1,3*NTRIS2
    TRIS1(3*NTRIS1+N) = TRIS1(3*NTRIS1+N) + NNODES1
  END DO
  NNODES1=NNODES_NEW
  NTRIS1=NTRIS_NEW
END SUBROUTINE MERGE_GEOM

! ------------------ FGETISOBOX ------------------------

SUBROUTINE FGETISOBOX(X,Y,Z,VALS,HAVE_TVALS,TVALS,LEVEL,XYZV_LOCAL,TV_LOCAL,NXYZV,TRIS,NTRIS)
  IMPLICIT NONE
  REAL(FB), DIMENSION(0:1), INTENT(IN) :: X, Y, Z
  INTEGER, INTENT(IN) :: HAVE_TVALS
  REAL(FB), DIMENSION(0:7), INTENT(IN) :: VALS,TVALS
  REAL(FB), INTENT(OUT), DIMENSION(0:35) :: XYZV_LOCAL,TV_LOCAL
  INTEGER, INTENT(OUT), DIMENSION(0:14) :: TRIS
  REAL(FB), INTENT(IN) :: LEVEL
  INTEGER, INTENT(OUT) :: NXYZV
  INTEGER, INTENT(OUT) :: NTRIS

  INTEGER, DIMENSION(0:14) :: COMPCASE=(/0,0,0,-1,0,0,-1,-1,0,0,0,0,-1,-1,0/)

  INTEGER, DIMENSION(0:11,0:1) :: EDGE2VERTEX                                              
  INTEGER, DIMENSION(0:1,0:11) :: EDGE2VERTEXTT=(/0,1,1,2,2,3,0,3,&
                                              0,4,1,5,2,6,3,7,&
                                              4,5,5,6,6,7,4,7/)

  INTEGER, POINTER, DIMENSION(:) :: CASE2
  INTEGER, TARGET,DIMENSION(0:255,0:9) :: CASES
  INTEGER, DIMENSION(0:9,0:255) :: CASEST=(/&
  0,0,0,0,0,0,0,0, 0,  0,0,1,2,3,4,5,6,7, 1,  1,1,2,3,0,5,6,7,4, 1,  2,&
  1,2,3,0,5,6,7,4, 2,  3,2,3,0,1,6,7,4,5, 1,  4,0,4,5,1,3,7,6,2, 3,  5,&
  2,3,0,1,6,7,4,5, 2,  6,3,0,1,2,7,4,5,6, 5,  7,3,0,1,2,7,4,5,6, 1,  8,&
  0,1,2,3,4,5,6,7, 2,  9,3,7,4,0,2,6,5,1, 3, 10,2,3,0,1,6,7,4,5, 5, 11,&
  3,0,1,2,7,4,5,6, 2, 12,1,2,3,0,5,6,7,4, 5, 13,0,1,2,3,4,5,6,7, 5, 14,&
  0,1,2,3,4,5,6,7, 8, 15,4,0,3,7,5,1,2,6, 1, 16,4,5,1,0,7,6,2,3, 2, 17,&
  1,2,3,0,5,6,7,4, 3, 18,5,1,0,4,6,2,3,7, 5, 19,2,3,0,1,6,7,4,5, 4, 20,&
  4,5,1,0,7,6,2,3, 6, 21,2,3,0,1,6,7,4,5, 6, 22,3,0,1,2,7,4,5,6,14, 23,&
  4,5,1,0,7,6,2,3, 3, 24,7,4,0,3,6,5,1,2, 5, 25,2,6,7,3,1,5,4,0, 7, 26,&
  3,0,1,2,7,4,5,6, 9, 27,2,6,7,3,1,5,4,0, 6, 28,4,0,3,7,5,1,2,6,11, 29,&
  0,1,2,3,4,5,6,7,12, 30,0,0,0,0,0,0,0,0, 0,  0,5,4,7,6,1,0,3,2, 1, 32,&
  0,3,7,4,1,2,6,5, 3, 33,1,0,4,5,2,3,7,6, 2, 34,4,5,1,0,7,6,2,3, 5, 35,&
  2,3,0,1,6,7,4,5, 3, 36,3,7,4,0,2,6,5,1, 7, 37,6,2,1,5,7,3,0,4, 5, 38,&
  0,1,2,3,4,5,6,7, 9, 39,3,0,1,2,7,4,5,6, 4, 40,3,7,4,0,2,6,5,1, 6, 41,&
  5,6,2,1,4,7,3,0, 6, 42,3,0,1,2,7,4,5,6,11, 43,3,0,1,2,7,4,5,6, 6, 44,&
  1,2,3,0,5,6,7,4,12, 45,0,1,2,3,4,5,6,7,14, 46,0,0,0,0,0,0,0,0, 0,  0,&
  5,1,0,4,6,2,3,7, 2, 48,1,0,4,5,2,3,7,6, 5, 49,0,4,5,1,3,7,6,2, 5, 50,&
  4,5,1,0,7,6,2,3, 8, 51,4,7,6,5,0,3,2,1, 6, 52,1,0,4,5,2,3,7,6,12, 53,&
  4,5,1,0,7,6,2,3,11, 54,0,0,0,0,0,0,0,0, 0,  0,5,1,0,4,6,2,3,7, 6, 56,&
  1,0,4,5,2,3,7,6,14, 57,0,4,5,1,3,7,6,2,12, 58,0,0,0,0,0,0,0,0, 0,  0,&
  4,0,3,7,5,1,2,6,10, 60,0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,&
  0,0,0,0,0,0,0,0, 0,  0,6,7,3,2,5,4,0,1, 1, 64,0,1,2,3,4,5,6,7, 4, 65,&
  1,0,4,5,2,3,7,6, 3, 66,0,4,5,1,3,7,6,2, 6, 67,2,1,5,6,3,0,4,7, 2, 68,&
  6,7,3,2,5,4,0,1, 6, 69,5,6,2,1,4,7,3,0, 5, 70,0,1,2,3,4,5,6,7,11, 71,&
  3,0,1,2,7,4,5,6, 3, 72,0,1,2,3,4,5,6,7, 6, 73,7,4,0,3,6,5,1,2, 7, 74,&
  2,3,0,1,6,7,4,5,12, 75,7,3,2,6,4,0,1,5, 5, 76,1,2,3,0,5,6,7,4,14, 77,&
  1,2,3,0,5,6,7,4, 9, 78,0,0,0,0,0,0,0,0, 0,  0,4,0,3,7,5,1,2,6, 3, 80,&
  0,3,7,4,1,2,6,5, 6, 81,2,3,0,1,6,7,4,5, 7, 82,5,1,0,4,6,2,3,7,12, 83,&
  2,1,5,6,3,0,4,7, 6, 84,0,1,2,3,4,5,6,7,10, 85,5,6,2,1,4,7,3,0,12, 86,&
  0,0,0,0,0,0,0,0, 0,  0,0,1,2,3,4,5,6,7, 7, 88,7,4,0,3,6,5,1,2,12, 89,&
  3,0,1,2,7,4,5,6,13, 90,0,0,0,0,0,0,0,0, 0,  0,7,3,2,6,4,0,1,5,12, 92,&
  0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,&
  5,4,7,6,1,0,3,2, 2, 96,6,2,1,5,7,3,0,4, 6, 97,2,1,5,6,3,0,4,7, 5, 98,&
  2,1,5,6,3,0,4,7,14, 99,1,5,6,2,0,4,7,3, 5,100,1,5,6,2,0,4,7,3,12,101,&
  1,5,6,2,0,4,7,3, 8,102,0,0,0,0,0,0,0,0, 0,  0,5,4,7,6,1,0,3,2, 6,104,&
  0,4,5,1,3,7,6,2,10,105,2,1,5,6,3,0,4,7,12,106,0,0,0,0,0,0,0,0, 0,  0,&
  5,6,2,1,4,7,3,0,11,108,0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,&
  0,0,0,0,0,0,0,0, 0,  0,7,6,5,4,3,2,1,0, 5,112,0,4,5,1,3,7,6,2,11,113,&
  6,5,4,7,2,1,0,3, 9,114,0,0,0,0,0,0,0,0, 0,  0,1,5,6,2,0,4,7,3,14,116,&
  0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,&
  7,6,5,4,3,2,1,0,12,120,0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,&
  0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,&
  0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,7,6,5,4,3,2,1,0, 1,128,&
  0,1,2,3,4,5,6,7, 3,129,1,2,3,0,5,6,7,4, 4,130,1,2,3,0,5,6,7,4, 6,131,&
  7,4,0,3,6,5,1,2, 3,132,1,5,6,2,0,4,7,3, 7,133,1,5,6,2,0,4,7,3, 6,134,&
  3,0,1,2,7,4,5,6,12,135,3,2,6,7,0,1,5,4, 2,136,4,0,3,7,5,1,2,6, 5,137,&
  7,4,0,3,6,5,1,2, 6,138,2,3,0,1,6,7,4,5,14,139,6,7,3,2,5,4,0,1, 5,140,&
  2,3,0,1,6,7,4,5, 9,141,1,2,3,0,5,6,7,4,11,142,0,0,0,0,0,0,0,0, 0,  0,&
  4,0,3,7,5,1,2,6, 2,144,3,7,4,0,2,6,5,1, 5,145,7,6,5,4,3,2,1,0, 6,146,&
  1,0,4,5,2,3,7,6,11,147,4,0,3,7,5,1,2,6, 6,148,3,7,4,0,2,6,5,1,12,149,&
  1,0,4,5,2,3,7,6,10,150,0,0,0,0,0,0,0,0, 0,  0,0,3,7,4,1,2,6,5, 5,152,&
  4,0,3,7,5,1,2,6, 8,153,0,3,7,4,1,2,6,5,12,154,0,0,0,0,0,0,0,0, 0,  0,&
  0,3,7,4,1,2,6,5,14,156,0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,&
  0,0,0,0,0,0,0,0, 0,  0,5,1,0,4,6,2,3,7, 3,160,1,2,3,0,5,6,7,4, 7,161,&
  1,0,4,5,2,3,7,6, 6,162,4,5,1,0,7,6,2,3,12,163,3,0,1,2,7,4,5,6, 7,164,&
  0,1,2,3,4,5,6,7,13,165,6,2,1,5,7,3,0,4,12,166,0,0,0,0,0,0,0,0, 0,  0,&
  3,2,6,7,0,1,5,4, 6,168,4,0,3,7,5,1,2,6,12,169,1,2,3,0,5,6,7,4,10,170,&
  0,0,0,0,0,0,0,0, 0,  0,6,7,3,2,5,4,0,1,12,172,0,0,0,0,0,0,0,0, 0,  0,&
  0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,6,5,4,7,2,1,0,3, 5,176,&
  0,4,5,1,3,7,6,2, 9,177,0,4,5,1,3,7,6,2,14,178,0,0,0,0,0,0,0,0, 0,  0,&
  6,5,4,7,2,1,0,3,12,180,0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,&
  0,0,0,0,0,0,0,0, 0,  0,5,4,7,6,1,0,3,2,11,184,0,0,0,0,0,0,0,0, 0,  0,&
  0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,&
  0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,&
  7,3,2,6,4,0,1,5, 2,192,6,5,4,7,2,1,0,3, 6,193,7,3,2,6,4,0,1,5, 6,194,&
  0,3,7,4,1,2,6,5,10,195,3,2,6,7,0,1,5,4, 5,196,3,2,6,7,0,1,5,4,12,197,&
  3,2,6,7,0,1,5,4,14,198,0,0,0,0,0,0,0,0, 0,  0,2,6,7,3,1,5,4,0, 5,200,&
  0,3,7,4,1,2,6,5,11,201,2,6,7,3,1,5,4,0,12,202,0,0,0,0,0,0,0,0, 0,  0,&
  3,2,6,7,0,1,5,4, 8,204,0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,&
  0,0,0,0,0,0,0,0, 0,  0,5,4,7,6,1,0,3,2, 5,208,3,7,4,0,2,6,5,1,14,209,&
  5,4,7,6,1,0,3,2,12,210,0,0,0,0,0,0,0,0, 0,  0,4,7,6,5,0,3,2,1,11,212,&
  0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,&
  6,7,3,2,5,4,0,1, 9,216,0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,&
  0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,&
  0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,4,7,6,5,0,3,2,1, 5,224,&
  4,7,6,5,0,3,2,1,12,225,1,5,6,2,0,4,7,3,11,226,0,0,0,0,0,0,0,0, 0,  0,&
  7,6,5,4,3,2,1,0, 9,228,0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,&
  0,0,0,0,0,0,0,0, 0,  0,2,6,7,3,1,5,4,0,14,232,0,0,0,0,0,0,0,0, 0,  0,&
  0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,&
  0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,&
  5,4,7,6,1,0,3,2, 8,240,0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,&
  0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,&
  0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,&
  0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,&
  0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,&
  0,0,0,0,0,0,0,0, 0,  0&
  /)

  INTEGER, TARGET,DIMENSION(0:14,0:12) :: PATHCCLIST
  INTEGER, DIMENSION(0:12,0:14) :: PATHCCLISTT=(/&
   0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,&
   3, 0, 1, 2,-1,-1,-1,-1,-1,-1,-1,-1,-1,&
   6,0,1,2,2,3,0,-1,-1,-1,-1,-1,-1,&
   6,0,1,2,3,4,5,-1,-1,-1,-1,-1,-1,&
   6,0,1,2,3,4,5,-1,-1,-1,-1,-1,-1,&
   9,0,1,2,2,3,4,0,2,4,-1,-1,-1,&
   9,0,1,2,2,3,0,4,5,6,-1,-1,-1,&
   9,0,1,2,3,4,5,6,7,8,-1,-1,-1,&
   6,0,1,2,2,3,0,-1,-1,-1,-1,-1,-1,&
  12,0,1,5,1,4,5,1,2,4,2,3,4,&
  12,0,1,2,0,2,3,4,5,6,4,6,7,&
  12,0,1,5,1,4,5,1,2,4,2,3,4,&
  12,0,1,2,3,4,5,3,5,6,3,6,7,&
  12,0,1,2,3,4,5,6,7,8,9,10,11,&
  12,0,1,5,1,4,5,1,2,4,2,3,4&
  /)

  INTEGER, TARGET,DIMENSION(0:14,0:19) :: PATHCCLIST2
  INTEGER, DIMENSION(0:19,0:14) :: PATHCCLIST2T=(/&
    0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,&
    0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,&
    0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,&
   12, 0, 1, 2, 0, 2, 3, 4, 5, 6, 4, 6, 7,-1,-1,-1,-1,-1,-1,-1,&
    0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,&
    0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,&
   15, 0, 1, 2, 0, 2, 3, 4, 5, 6, 7, 8, 9, 7, 9,10,-1,-1,-1,-1,&
   15, 0, 1, 2, 3, 4, 5, 3, 5, 7, 3, 7, 8, 5, 6, 7,-1,-1,-1,-1,&
    0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,&
    0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,&
   12, 0, 1, 2, 0, 2, 3, 4, 5, 6, 4, 6, 7,-1,-1,-1,-1,-1,-1,-1,&
    0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,&
   12, 0, 1, 2, 3, 4, 6, 3, 6, 7, 4, 5, 6,-1,-1,-1,-1,-1,-1,-1,&
   12, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9,10,11,-1,-1,-1,-1,-1,-1,-1,&
    0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1&
   /)

  INTEGER, POINTER,DIMENSION(:) :: PATH
  INTEGER, TARGET,DIMENSION(0:14,0:12) :: PATHCCWLIST
  INTEGER, DIMENSION(0:12,0:14) :: PATHCCWLISTT=(/&
   0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,&
   3, 0, 2, 1,-1,-1,-1,-1,-1,-1,-1,-1,-1,&
   6, 0, 2, 1, 0, 3, 2,-1,-1,-1,-1,-1,-1,&
   6, 0, 2, 1, 3, 5, 4,-1,-1,-1,-1,-1,-1,&
   6, 0, 2, 1, 3, 5, 4,-1,-1,-1,-1,-1,-1,&
   9, 0, 2, 1, 2, 4, 3, 0, 4, 2,-1,-1,-1,&
   9, 0, 2, 1, 0, 3, 2, 4, 6, 5,-1,-1,-1,&
   9, 0, 2, 1, 3, 5, 4, 6, 8, 7,-1,-1,-1,&
   6, 0, 2, 1, 0, 3, 2,-1,-1,-1,-1,-1,-1,&
  12, 0, 5, 1, 1, 5, 4, 1, 4, 2, 2, 4, 3,&
  12, 0, 2, 1, 0, 3, 2, 4, 6, 5, 4, 7, 6,&
  12, 0, 5, 1, 1, 5, 4, 1, 4, 2, 2, 4, 3,&
  12, 0, 2, 1, 3, 5, 4, 3, 6, 5, 3, 7, 6,&
  12, 0, 2, 1, 3, 5, 4, 6, 8, 7, 9,11,10,&
  12, 0, 5, 1, 1, 5, 4, 1, 4, 2, 2, 4, 3&
   /)

  INTEGER, TARGET,DIMENSION(0:14,0:18) :: PATHCCWLIST2
  INTEGER, DIMENSION(0:18,0:14) :: PATHCCWLIST2T=(/&
   0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,&
   0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,&
   0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,&
  12, 0, 2, 1, 0, 3, 2, 4, 6, 5, 4, 7, 6,-1,-1,-1,-1,-1,-1,&
   0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,&
   0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,&
  15, 0, 2, 1, 0, 3, 2, 4, 6, 5, 7, 9, 8, 7,10, 9,-1,-1,-1,&
  15, 0, 2, 1, 3, 5, 4, 3, 7, 5, 3, 8, 7, 5, 7, 6,-1,-1,-1,&
   0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,&
   0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,&
  12, 0, 2, 1, 0, 3, 2, 4, 6, 5, 4, 7, 6,-1,-1,-1,-1,-1,-1,&
   0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,&
  12, 0, 2, 1, 3, 6, 4, 3, 7, 6, 4, 6, 5,-1,-1,-1,-1,-1,-1,&
  12, 0, 2, 1, 3, 5, 4, 6, 8, 7, 9,11,10,-1,-1,-1,-1,-1,-1,&
   0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1&
  /)


  INTEGER, POINTER,DIMENSION(:) :: EDGES
  INTEGER, TARGET,DIMENSION(0:14,0:12) :: EDGELIST
  INTEGER, DIMENSION(0:12,0:14) :: EDGELISTT=(/&
   0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,&
   3, 0, 4, 3,-1,-1,-1,-1,-1,-1,-1,-1,-1,&
   4, 0, 4, 7, 2,-1,-1,-1,-1,-1,-1,-1,-1,&
   6, 0, 4, 3, 7,11,10,-1,-1,-1,-1,-1,-1,&
   6, 0, 4, 3, 6,10, 9,-1,-1,-1,-1,-1,-1,&
   5, 0, 3, 7, 6, 5,-1,-1,-1,-1,-1,-1,-1,&
   7, 0, 4, 7, 2, 6,10, 9,-1,-1,-1,-1,-1,&
   9, 4, 8,11, 2, 3, 7, 6,10, 9,-1,-1,-1,&
   4, 4, 7, 6, 5,-1,-1,-1,-1,-1,-1,-1,-1,&
   6, 2, 6, 9, 8, 4, 3,-1,-1,-1,-1,-1,-1,&
   8, 0, 8,11, 3,10, 9, 1, 2,-1,-1,-1,-1,&
   6, 4, 3, 2,10, 9, 5,-1,-1,-1,-1,-1,-1,&
   8, 4, 8,11, 0, 3, 7, 6, 5,-1,-1,-1,-1,&
  12, 0, 4, 3, 7,11,10, 2, 6, 1, 8, 5, 9,&
   6, 3, 7, 6, 9, 8, 0,-1,-1,-1,-1,-1,-1&
  /)

  INTEGER, TARGET,DIMENSION(0:14,0:15) :: EDGELIST2
  INTEGER, DIMENSION(0:15,0:14) :: EDGELIST2T=(/&
   0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,&
   0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,&
   0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,&
   8, 3, 0,10, 7, 0, 4,11,10,-1,-1,-1,-1,-1,-1,-1,&
   0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,&
   0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,&
  11, 7,10, 9, 4, 0, 4, 9, 0, 9, 6, 2,-1,-1,-1,-1,&
   9, 7,10,11, 3, 4, 8, 9, 6, 2,-1,-1,-1,-1,-1,-1,&
   0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,&
   0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,&
   8, 0, 8, 9, 1, 3, 2,10,11,-1,-1,-1,-1,-1,-1,-1,&
   0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,&
   8, 0, 3, 4, 8,11, 7, 6, 5,-1,-1,-1,-1,-1,-1,-1,&
  12, 4,11, 8, 0, 5, 1, 7, 3, 2, 9,10, 6,-1,-1,-1,&
   0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1&
  /)
  
  REAL(FB) :: VMIN, VMAX
  INTEGER :: CASENUM, BIGGER, SIGN, N
  INTEGER, DIMENSION(0:7) :: PRODS=(/1,2,4,8,16,32,64,128/);
  REAL(FB), DIMENSION(0:7) :: XXVAL,YYVAL,ZZVAL
  INTEGER, DIMENSION(0:3) :: IXMIN=(/0,1,4,5/), IXMAX=(/2,3,6,7/)
  INTEGER, DIMENSION(0:3) :: IYMIN=(/0,3,4,7/), IYMAX=(/1,2,5,6/)
  INTEGER, DIMENSION(0:3) :: IZMIN=(/0,1,2,3/), IZMAX=(/4,5,6,7/)
  INTEGER :: TYPE2,THISTYPE2
  INTEGER :: NEDGES,NPATH
  INTEGER :: OUTOFBOUNDS, EDGE, V1, V2
  REAL(FB) :: VAL1, VAL2, DENOM, FACTOR
  REAL(FB) :: XX, YY, ZZ

  EDGE2VERTEX=TRANSPOSE(EDGE2VERTEXTT)
  CASES=TRANSPOSE(CASEST)
  PATHCCLIST=TRANSPOSE(PATHCCLISTT)
  PATHCCLIST2=TRANSPOSE(PATHCCLIST2T)
  PATHCCWLIST=TRANSPOSE(PATHCCWLISTT)
  PATHCCWLIST2=TRANSPOSE(PATHCCWLIST2T)
  EDGELIST=TRANSPOSE(EDGELISTT)
  EDGELIST2=TRANSPOSE(EDGELIST2T)

  VMIN=MIN(VALS(0),VALS(1),VALS(2),VALS(3),VALS(4),VALS(5),VALS(6),VALS(7))
  VMAX=MAX(VALS(0),VALS(1),VALS(2),VALS(3),VALS(4),VALS(5),VALS(6),VALS(7))


  NXYZV=0
  NTRIS=0

  IF (VMIN>LEVEL.OR.VMAX<LEVEL) RETURN

  CASENUM=0
  BIGGER=0
  SIGN=1

  DO N = 0, 7
    IF (VALS(N)>LEVEL) THEN
      BIGGER=BIGGER+1
      CASENUM = CASENUM + PRODS(N);
    ENDIF
  END DO

! THERE ARE MORE NODES GREATER THAN THE ISO-SURFACE LEVEL THAN BELOW, SO 
!   SOLVE THE COMPLEMENTARY PROBLEM 

  IF (BIGGER > 4) THEN
    SIGN=-1
    CASENUM=0
    DO N=0, 7
      IF (VALS(N)<LEVEL) THEN
        CASENUM = CASENUM + PRODS(N)
      ENDIF
    END DO
  ENDIF

! STUFF MIN AND MAX GRID DATA INTO A MORE CONVENIENT FORM 
!  ASSUMING THE FOLLOWING GRID NUMBERING SCHEME

!       5-------6
!     / |      /| 
!   /   |     / | 
!  4 -------7   |
!  |    |   |   |  
!  Z    1---|---2
!  |  Y     |  /
!  |/       |/
!  0--X-----3     


  DO N=0, 3
    XXVAL(IXMIN(N)) = X(0);
    XXVAL(IXMAX(N)) = X(1);
    YYVAL(IYMIN(N)) = Y(0);
    YYVAL(IYMAX(N)) = Y(1);
    ZZVAL(IZMIN(N)) = Z(0);
    ZZVAL(IZMAX(N)) = Z(1);
  END DO

  IF (CASENUM<=0.OR.CASENUM>=255) THEN ! NO ISO-SURFACE 
    NTRIS=0
    RETURN
  ENDIF

  CASE2(0:9) => CASES(CASENUM,0:9)
  TYPE2 = CASE2(8);
  IF (TYPE2==0) THEN
    NTRIS=0
    RETURN
  ENDIF

  IF (COMPCASE(TYPE2) == -1) THEN
    THISTYPE2=SIGN
  ELSE
    THISTYPE2=1
  ENDIF
  
  IF (THISTYPE2 /= -1) THEN
    !EDGES = &(EDGELIST[TYPE][1]);
    EDGES(-1:12) => EDGELIST(TYPE2,0:13)
    IF (SIGN >=0) THEN
     ! PATH = &(PATHCCLIST[TYPE][1])   !  CONSTRUCT TRIANGLES CLOCK WISE
      PATH(-1:12) => PATHCCLIST(TYPE2,0:13)
    ELSE
     ! PATH = &(PATHCCWLIST[TYPE][1])  !  CONSTRUCT TRIANGLES COUNTER CLOCKWISE 
      PATH(-1:15) => PATHCCWLIST(TYPE2,0:16)
    ENDIF
  ELSE
    !EDGES = &(EDGELIST2[TYPE][1]);
    EDGES(-1:12) => EDGELIST2(TYPE2,0:13)
    IF (SIGN > 0) THEN
     ! PATH = &(PATHCCLIST2[TYPE][1])  !  CONSTRUCT TRIANGLES CLOCK WISE
      PATH(-1:17) => PATHCCLIST2(TYPE2,0:18)
    ELSE
     ! PATH = &(PATHCCWLIST2[TYPE][1]) !  CONSTRUCT TRIANGLES COUNTER CLOCKWISE
      PATH(-1:15) => PATHCCWLIST2(TYPE2,0:16)
    ENDIF   
  ENDIF
  NPATH = PATH(-1);
  NEDGES = EDGES(-1);
  
  OUTOFBOUNDS=0
  DO N=0,NEDGES-1
    EDGE = EDGES(N)
    V1 = CASE2(EDGE2VERTEX(EDGE,0));
    V2 = CASE2(EDGE2VERTEX(EDGE,1));
    VAL1 = VALS(V1)-LEVEL
    VAL2 = VALS(V2)-LEVEL
    DENOM = VAL2 - VAL1
    FACTOR = 0.5
    IF (DENOM /= 0.0)FACTOR = -VAL1/DENOM
    XX = FMIX(FACTOR,XXVAL(V1),XXVAL(V2));
    YY = FMIX(FACTOR,YYVAL(V1),YYVAL(V2));
    ZZ = FMIX(FACTOR,ZZVAL(V1),ZZVAL(V2));
    XYZV_LOCAL(3*N) = XX;
    XYZV_LOCAL(3*N+1) = YY;
    XYZV_LOCAL(3*N+2) = ZZ;
    IF (HAVE_TVALS == 1) THEN
      TV_LOCAL(N) = FMIX(FACTOR,TVALS(V1),TVALS(V2));
    ENDIF

  END DO

! COPY COORDINATES TO OUTPUT ARRAY

  NXYZV = NEDGES;
  NTRIS = NPATH/3;
  IF (NPATH > 0) THEN
    TRIS(0:NPATH-1) = PATH(0:NPATH-1)
  ENDIF
  RETURN
END SUBROUTINE FGETISOBOX


! ------------------ UPDATEISOSURFACE ------------------------

SUBROUTINE UPDATEISOSURFACE(XYZVERTS_LOCAL, NXYZVERTS_LOCAL, TRIS_LOCAL, NTRIS_LOCAL,  &
                            XYZVERTS, NXYZVERTS, NXYZVERTS_MAX, TRIANGLES, NTRIANGLES, NTRIANGLES_MAX)
  REAL(FB), INTENT(IN), DIMENSION(0:35) :: XYZVERTS_LOCAL
  INTEGER, INTENT(IN) :: NXYZVERTS_LOCAL
  INTEGER, INTENT(IN), DIMENSION(0:14) :: TRIS_LOCAL
  INTEGER, INTENT(IN) :: NTRIS_LOCAL
  REAL(FB), POINTER, DIMENSION(:) :: XYZVERTS
  INTEGER, INTENT(INOUT) :: NXYZVERTS, NXYZVERTS_MAX, NTRIANGLES, NTRIANGLES_MAX
  INTEGER, POINTER, DIMENSION(:) :: TRIANGLES
  
  INTEGER :: NXYZVERTS_NEW, NTRIANGLES_NEW
    
  NXYZVERTS_NEW = NXYZVERTS + NXYZVERTS_LOCAL
  NTRIANGLES_NEW = NTRIANGLES + NTRIS_LOCAL
  IF (1+NXYZVERTS_NEW > NXYZVERTS_MAX) THEN
    NXYZVERTS_MAX=1+NXYZVERTS_NEW+1000
    CALL REALLOCATE_F('UPDATEISOSURFACES','XYZVERTS',XYZVERTS,3*NXYZVERTS,3*NXYZVERTS_MAX)
  ENDIF
  IF (1+NTRIANGLES_NEW > NTRIANGLES_MAX) THEN
    NTRIANGLES_MAX=1+NTRIANGLES_NEW+1000
    CALL REALLOCATE_I('UPDATEISOSURFACES','TRIANGLES',TRIANGLES,3*NTRIANGLES,3*NTRIANGLES_MAX)
  ENDIF
  XYZVERTS(1+3*NXYZVERTS:3*NXYZVERTS_NEW)   =XYZVERTS_LOCAL(0:3*NXYZVERTS_LOCAL-1)
  TRIANGLES(1+3*NTRIANGLES:3*NTRIANGLES_NEW)=NXYZVERTS+TRIS_LOCAL(0:3*NTRIS_LOCAL-1)
  NXYZVERTS = NXYZVERTS_NEW
  NTRIANGLES = NTRIANGLES_NEW
  RETURN
END SUBROUTINE UPDATEISOSURFACE

! ------------------ REALLOCATE_I ------------------------

SUBROUTINE REALLOCATE_I(ROUTINE,VAR,VALS,OLDSIZE,NEWSIZE)
  CHARACTER(*), INTENT(IN) :: ROUTINE, VAR
  INTEGER, DIMENSION(:), POINTER :: VALS
  INTEGER, INTENT(IN) :: OLDSIZE, NEWSIZE
  INTEGER, DIMENSION(:), ALLOCATABLE :: VALS_TEMP
  INTEGER :: MEMERR
  
  IF (OLDSIZE > 0) THEN
    ALLOCATE(VALS_TEMP(OLDSIZE),STAT=MEMERR)
    CALL ChkMemErr(ROUTINE,VAR//'_TEMP',MEMERR)
    VALS_TEMP(1:OLDSIZE) = VALS(1:OLDSIZE)
    DEALLOCATE(VALS)
  ENDIF
  ALLOCATE(VALS(NEWSIZE),STAT=MEMERR)
  CALL ChkMemErr(ROUTINE,VAR,MEMERR)
  IF (OLDSIZE > 0) THEN
    VALS(1:OLDSIZE)=VALS_TEMP(1:OLDSIZE)
    DEALLOCATE(VALS_TEMP)
  ENDIF
  RETURN
END SUBROUTINE REALLOCATE_I

! ------------------ REALLOCATE_F ------------------------

SUBROUTINE REALLOCATE_F(ROUTINE,VAR,VALS,OLDSIZE,NEWSIZE)
  CHARACTER(*), INTENT(IN) :: ROUTINE,VAR
  REAL(FB), INTENT(INOUT), DIMENSION(:), POINTER :: VALS
  INTEGER, INTENT(IN) :: OLDSIZE, NEWSIZE
  REAL(FB), DIMENSION(:), ALLOCATABLE :: VALS_TEMP
  INTEGER :: MEMERR
  
  IF (OLDSIZE > 0) THEN
    ALLOCATE(VALS_TEMP(OLDSIZE),STAT=MEMERR)
    CALL ChkMemErr(ROUTINE,VAR//'_TEMP',MEMERR)
    VALS_TEMP(1:OLDSIZE) = VALS(1:OLDSIZE)
    DEALLOCATE(VALS)
  ENDIF
  ALLOCATE(VALS(NEWSIZE),STAT=MEMERR)
  CALL ChkMemErr(ROUTINE,VAR,MEMERR)
  IF (OLDSIZE > 0) THEN
    VALS(1:OLDSIZE)=VALS_TEMP(1:OLDSIZE)
    DEALLOCATE(VALS_TEMP)
  ENDIF
  RETURN
END SUBROUTINE REALLOCATE_F

! ------------------ FMIX ------------------------

REAL(FB) FUNCTION FMIX(F,A,B)
  REAL(FB), INTENT(IN) :: F, A, B

  FMIX = (1.0-F)*A + F*B
  RETURN
END FUNCTION FMIX

! ------------------ FSMOKE3DTOFILE ------------------------

SUBROUTINE SMOKE3D_TO_FILE(LU_SMOKE3D,LU_SMOKE3D_SIZE,TIME,DX,EXTCOEF,SMOKE_TYPE,VALS,NX,NY,NZ,HRRPUV_MAX_SMV)
  INTEGER, INTENT(INOUT) :: LU_SMOKE3D, LU_SMOKE3D_SIZE
  REAL(FB), INTENT(IN) :: TIME, DX, EXTCOEF
  INTEGER, INTENT(IN) :: SMOKE_TYPE
  REAL(FB), INTENT(IN), DIMENSION(NX*NY*NZ) :: VALS
  INTEGER, INTENT(IN) :: NX,NY,NZ
  REAL(FB), INTENT(IN) :: HRRPUV_MAX_SMV
  
  INTEGER, PARAMETER :: SOOT=1, FIRE=2, OTHER=3
  CHARACTER(LEN=1), DIMENSION(:), POINTER :: BUFFER_IN, BUFFER_OUT
  INTEGER :: NCHARS_IN
  REAL(FB) :: FACTOR,VAL
  REAL(FB) :: CUTMAX
  INTEGER :: I, NCHARS_OUT
  INTEGER :: FIRST, NVALS, ONE=1, VERSION=0
  INTEGER :: MEMERR
  
  NVALS=NX*NY*NZ
  NCHARS_IN=NVALS
  
  IF (NVALS < 1) RETURN
  
  IF (LU_SMOKE3D<0.OR.LU_SMOKE3D_SIZE<0) THEN
     LU_SMOKE3D=ABS(LU_SMOKE3D)
     LU_SMOKE3D_SIZE=ABS(LU_SMOKE3D_SIZE)
     FIRST=1
     WRITE(LU_SMOKE3D_SIZE,*)VERSION
     WRITE(LU_SMOKE3D)ONE,VERSION,0,NX-1,0,NY-1,0,NZ-1
  ELSE
     FIRST=0
  ENDIF
  
  ALLOCATE(BUFFER_IN(NVALS),STAT=MEMERR)
  CALL ChkMemErr('SMOKE3D_TO_FILE','BUFFER_IN',MEMERR)
  ALLOCATE(BUFFER_OUT(NVALS),STAT=MEMERR)
  CALL ChkMemErr('SMOKE3D_TO_FILE','BUFFER_OUT',MEMERR)
  
  IF (SMOKE_TYPE == SOOT) THEN
    FACTOR=-EXTCOEF*DX
    DO I = 1, NVALS
      VAL=MAX(0.0,VALS(I))
      BUFFER_IN(I)=CHAR(INT(254*(1.0-EXP( FACTOR*VAL))))
    END DO
    CALL RLE_F(BUFFER_IN,NCHARS_IN,BUFFER_OUT,NCHARS_OUT)
  ELSE IF (SMOKE_TYPE == FIRE) THEN
    CUTMAX=HRRPUV_MAX_SMV
    IF (CUTMAX < 0.0)CUTMAX=1.0;
    DO I=1,NVALS
      VAL=MAX(0.0,VALS(I))
      VAL=MIN(CUTMAX,VAL)
      BUFFER_IN(I)=CHAR(INT(254*(VAL/CUTMAX)));
    END DO
    CALL RLE_F(BUFFER_IN,NCHARS_IN,BUFFER_OUT,NCHARS_OUT)
  ELSE
    NCHARS_OUT=0
  ENDIF
  
  WRITE(LU_SMOKE3D_SIZE,*)TIME,NCHARS_IN,NCHARS_OUT
  WRITE(LU_SMOKE3D)TIME
  WRITE(LU_SMOKE3D)NCHARS_IN,NCHARS_OUT
  IF (NCHARS_OUT > 0)WRITE(LU_SMOKE3D)(BUFFER_OUT(I),I=1,NCHARS_OUT)
  
  DEALLOCATE(BUFFER_IN)
  DEALLOCATE(BUFFER_OUT)
  
 END SUBROUTINE SMOKE3D_TO_FILE    

! ------------------ RLE_F ------------------------

SUBROUTINE RLE_F(BUFFER_IN, NCHARS_IN, BUFFER_OUT, NCHARS_OUT)
  CHARACTER(LEN=1), INTENT(IN), DIMENSION(NCHARS_IN) :: BUFFER_IN
  INTEGER, INTENT(IN) :: NCHARS_IN
  CHARACTER(LEN=1), INTENT(OUT), DIMENSION(:), POINTER :: BUFFER_OUT
  INTEGER, INTENT(OUT) :: NCHARS_OUT
  
  CHARACTER(LEN=1) :: MARK=CHAR(255),THISCHAR,LASTCHAR
  INTEGER :: N,N2,NREPEATS
  
   NREPEATS=1
   LASTCHAR=MARK
   N2=1
   DO N=1,NCHARS_IN
     THISCHAR=BUFFER_IN(N)
     IF (THISCHAR == LASTCHAR) THEN
       NREPEATS=NREPEATS+1
     ELSE
       NREPEATS=1
     ENDIF
     IF (NREPEATS >=1.AND.NREPEATS <= 3) THEN
       BUFFER_OUT(N2)=THISCHAR
       LASTCHAR=THISCHAR
     ELSE 
       IF (NREPEATS == 4) THEN
         N2=N2-3
         BUFFER_OUT(N2)=MARK
         BUFFER_OUT(N2+1)=THISCHAR
         N2=N2+2
       ELSE
         N2=N2-1
       ENDIF
       BUFFER_OUT(N2)=CHAR(NREPEATS)
       IF (NREPEATS == 254) THEN
         NREPEATS=1
         LASTCHAR=MARK
       ENDIF
     ENDIF
     N2=N2+1
   END DO
   NCHARS_OUT=N2-1
   RETURN
END SUBROUTINE RLE_F

END MODULE ISOSMOKE            

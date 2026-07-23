// ============================================================================
// Inflow: triangular-prism mesh
//
// Tank:
//   x = 0.0 to 3.0 m
//   y = 0.0 to 2.0 m
//   z = 0.0 to 0.15 m
//
// Guide channel:
//   x = -0.60 to 0.0 m
//   width  = 0.11 m
//   height = 0.055 m
//
// Mesh:
//   tank horizontal size   = 0.015 m
//   inlet horizontal size  = 0.010 m
//   vertical size          = 0.005 m
// ============================================================================

// Geometry
L  = 3.0;
W  = 2.0;
H  = 0.15;

CL = 0.60;

ow = 0.11;
oh = 0.055;

y1 = W/2 - ow/2;
y2 = W/2 + ow/2;

// Mesh sizes
lcTank = 0.015;
lcOpen = 0.010;

// Vertical layers
dz       = 0.005;
nLower = 6;   // 0.055 / 0.005
nUpper = 10;   // (0.15 - 0.055) / 0.005

eps = 1e-7;

// ============================================================================
// Two-dimensional bottom geometry
// ============================================================================

// Tank corner and opening points
Point(1) = {0,  0,  0, lcTank};
Point(2) = {L,  0,  0, lcTank};
Point(3) = {L,  W,  0, lcTank};
Point(4) = {0,  W,  0, lcTank};

Point(5) = {0, y2, 0, lcOpen};
Point(6) = {0, y1, 0, lcOpen};

// Guide-channel upstream points
Point(7) = {-CL, y1, 0, lcOpen};
Point(8) = {-CL, y2, 0, lcOpen};

// Tank boundary curves
Line(1) = {1, 2};
Line(2) = {2, 3};
Line(3) = {3, 4};
Line(4) = {4, 5};

// Shared line between tank and guide channel
Line(5) = {5, 6};

Line(6) = {6, 1};

// Guide-channel boundary curves
Line(7) = {6, 7};
Line(8) = {7, 8};   // inletOutlet
Line(9) = {8, 5};

// Tank bottom surface
tankLoop = newll;
Curve Loop(tankLoop) = {1, 2, 3, 4, 5, 6};

tankBase = news;
Plane Surface(tankBase) = {tankLoop};

// Guide-channel bottom surface
channelLoop = newll;
Curve Loop(channelLoop) = {7, 8, 9, 5};

channelBase = news;
Plane Surface(channelBase) = {channelLoop};

// ============================================================================
// Lower extrusion: z = 0 to 0.055 m
//
// Both surfaces are extruded together so the tank-channel interface is
// conformal.
// ============================================================================

lower[] = Extrude {0, 0, oh}
{
    Surface{tankBase, channelBase};
    Layers{nLower};
    Recombine;
};

// Find the top surface of the lower tank.
// The guide-channel top is excluded because its x-range includes x = -0.60 m.
tankTopAtChannelHeight() =
    Surface In BoundingBox
    {
        -eps, -eps, oh-eps,
        L+eps, W+eps, oh+eps
    };

// ============================================================================
// Upper tank extrusion: z = 0.055 to 0.15 m
// ============================================================================

upper[] = Extrude {0, 0, H-oh}
{
    Surface{tankTopAtChannelHeight(0)};
    Layers{nUpper};
    Recombine;
};

// ============================================================================
// Identify volumes and external boundaries
// ============================================================================

fluidVolumes() = Volume{:};

outerBoundary() =
    CombinedBoundary
    {
        Volume{fluidVolumes()};
    };

// Upper open boundary of the tank
atmosphereSurfaces() =
    Surface In BoundingBox
    {
        -eps, -eps, H-eps,
        L+eps, W+eps, H+eps
    };

// Upstream end of the guide channel
inletSurfaces() =
    Surface In BoundingBox
    {
        -CL-eps, y1-eps, -eps,
        -CL+eps, y2+eps, oh+eps
    };

// All remaining external surfaces are solid walls
wallSurfaces() = outerBoundary();
wallSurfaces() -= atmosphereSurfaces();
wallSurfaces() -= inletSurfaces();

// ============================================================================
// Physical groups for OpenFOAM
// ============================================================================

Physical Surface("inletOutlet") =
{
    inletSurfaces()
};

Physical Surface("atmosphere") =
{
    atmosphereSurfaces()
};

Physical Surface("walls") =
{
    wallSurfaces()
};

Physical Volume("fluid") =
{
    fluidVolumes()
};

// ============================================================================
// Mesh controls
// ============================================================================

Mesh.MeshSizeMin = lcOpen;
Mesh.MeshSizeMax = lcTank;

Mesh.MeshSizeFromPoints = 1;
Mesh.MeshSizeExtendFromBoundary = 1;
Mesh.MeshSizeFromCurvature = 0;

Mesh.Algorithm = 6;
Mesh.ElementOrder = 1;

// OpenFOAM gmshToFoam compatibility
Mesh.MshFileVersion = 2.2;
Mesh.Binary = 0;

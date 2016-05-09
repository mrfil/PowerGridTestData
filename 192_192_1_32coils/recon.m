
tic
load kx
load ky
load kz
load SMap
load t
load data
load FM
kz = 0; %PowerGrid needs length(kz) = length(kx) = length(ky) but our matlab code interprets that as a 3D encoding
L = 5;
FOV = 24;
N = 192;
nsl = 1;
J = 5;
ncoils = 32;

A = fast_mr_v2(col(kx),col(ky),col(kz),FOV,N,N,nsl,2*N,2*N,2*nsl,J,t,FM,0,L,1,[],0);
As = sense(A,reshape(SMap,N*N,ncoils));

R = Robject(ones(N,N),'edge_type','tight','order',1,'beta',10000,'type_denom','matlab','potential','quad');
xinit = zeros(N*N,1);

%POCS-SENSE like algorithm
%Form inital guess from an adjoint projection
x = (1/(2*N)).*(As'*data);
for ii = 1:100
    dataEst = (1/(2*N)).*(As*x);
    xError = (1/(2*N)).*(As'*(data - dataEst));
    x = x+xError;
end

toc

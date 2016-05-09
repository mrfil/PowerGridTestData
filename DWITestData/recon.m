clear
tic
load kx 
load ky
load kz
load SMap
load PMap
load t
load data
load FM

L = 13;
FOV = 24;
N = 120;
nsl = 4;
J = 5;
ncoils = 32;
nl = 4;

%P = reshape(exp(1j*angle(PMap)),[N*N*nsl,nl]);
data = reshape(data,[length(data)/(ncoils*nl),nl,ncoils]);
data = permute(data,[1,3,2]);
P = reshape(PMap,[N*N*nsl,nl]);
%A = fast_mr_v2(col(kx),col(ky),col(kz),FOV,N,N,nsl,2*N,2*N,2*nsl,J,t,FM,0,L,1,[],0);
%S = sense(A,reshape(SMap,N*N*nsl,ncoils));

S = CGobj(reshape(kx,[length(kx)/nl,nl]), reshape(ky,[length(ky)/nl,nl]), reshape(kz,[length(kz)/nl,nl]), FOV, N, N, nsl, 4, P, reshape(SMap,[length(SMap)/32,32]),t(1:end/nl),FM,L,logical(ones(120,120,4)),32);
%S = CGobj(kx, ky, kz, FOV, N, N, nsl,nl,P, reshape(SMap,[length(SMap)/32,32]),1,FM,L,logical(ones(120,120,4)),32);


R = Robject(ones(N,N,nsl),'edge_type','tight','order',1,'beta',1,'type_denom','matlab','potential','quad');
xinit = zeros(N*N*nsl,1);

cimg = solve_pwls_pcg(xinit, S, 1, col(data), R, 'niter', 10);
toc
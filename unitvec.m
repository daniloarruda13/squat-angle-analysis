function [y] = unitvec(x)
%Creats a unit vector by dividing the vector by its magnitude.
[n d]=size(x);
for f=1:n;
  mag = (sqrt(sum(x(f,1:3).^2)));
  y(f,1:3)=x(f,1:3)./mag;
end
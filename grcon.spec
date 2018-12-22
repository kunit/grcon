%define name grcon
%define release 1.el7
%define version 0.2.0
%define buildroot %{_tmppath}/%{name}-%{version}-buildroot
%define debug_package %{nil}

BuildRoot: %{buildroot}
Summary: grcon is a lightweight resource virtualization tool for linux processes. This is one-binary.
License: MIT
Packager: TAKAHASHI Kunihiko <kunihiko.takahashi@gmail.com>
Source: %{name}-%{version}.tar.gz
Name: %{name}
Version: %{version}
Release: %{release}
Prefix: %{_prefix}
Group: Applications/Internet

%description
grcon is a lightweight resource virtualization tool for linux processes. This is one-binary.

%prep
%setup -q -n %{name}-%{version}

%build
make

%install
%{__rm} -rf %{buildroot}
mkdir -p %{buildroot}%{_bindir}
make BINDIR=%{buildroot}%{_bindir} install

%clean
%{__rm} -rf %{buildroot}

%files
%{_bindir}/grcon

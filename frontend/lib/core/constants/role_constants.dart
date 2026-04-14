class RoleConstants {
  static const superAdmin = 'super_admin';
  static const consumer = 'consumer';
  static const serviceOfficer = 'service_officer';
  static const admin = 'admin';
  static const gudang = 'gudang';
  static const finance = 'finance';
  static const driver = 'driver';
  static const dekor = 'dekor';
  static const konsumsi = 'konsumsi';
  static const supplier = 'supplier';
  static const owner = 'owner';
  static const pemukaAgama = 'pemuka_agama';
  static const hrd = 'hrd';
  static const viewer = 'viewer';
  static const tukangFoto = 'tukang_foto';
  static const tukangAngkatPeti = 'tukang_angkat_peti';
  static const purchasing = 'purchasing';

  static const vendorRoles = [dekor, konsumsi, supplier, pemukaAgama, tukangFoto, tukangAngkatPeti];
  static const viewerRoles = [viewer];
  static const internalRoles = [serviceOfficer, admin, gudang, finance, driver, owner, hrd, purchasing];
  static const activeRoles = [consumer, serviceOfficer, admin, gudang, finance, driver, dekor, konsumsi, supplier, owner, pemukaAgama, hrd, viewer, tukangFoto, tukangAngkatPeti, purchasing];
}

#include "filtermodel.h"

// --------------------------------------------------------------------------------------------------------------------
// ListModelPrivate
// --------------------------------------------------------------------------------------------------------------------
ListModelPrivate::ListModelPrivate(QObject *parent)
    : QAbstractItemModel(parent) {
    m_dataList = new QList<QMap<QString, QVariant> >;
    m_rowCount = -1;

    connect(this, SIGNAL(rowsInserted(QModelIndex,int,int)), SLOT(rowsInsertedOrDeleted()));
    connect(this, SIGNAL(rowsRemoved(QModelIndex,int,int)), SLOT(rowsInsertedOrDeleted()));
}

ListModelPrivate::~ListModelPrivate() {
    delete m_dataList;
}

void ListModelPrivate::setRoleNameList(QVariantList roleNameList) {
    for(int i = 0; i < roleNameList.size(); i++) {
        QVariant variant = roleNameList.at(i);

        QString roleName = variant.toString();
        m_roleNames.insert(i,roleName.toUtf8());
        m_roleNamesReverse.insert(roleName.toUtf8(), i);
    }
}

QHash<int, QByteArray> ListModelPrivate::roleNames() const {
    return m_roleNames;
}

QModelIndex ListModelPrivate::parent(const QModelIndex &child) const {
    Q_UNUSED(child)
    return QModelIndex();
}

QModelIndex ListModelPrivate::index(int row, int column, const QModelIndex &parent) const {
    Q_UNUSED(parent)
    if (row < 0 || column < 0 || row >= m_dataList->size() || column >= m_roleNames.size()) {
        return QModelIndex();
    }
    return createIndex(row, column, m_dataList);
}

int ListModelPrivate::rowCount(const QModelIndex &parent) const {
    Q_UNUSED(parent)
    return m_dataList->size();
}

int ListModelPrivate::columnCount(const QModelIndex &parent) const {
    Q_UNUSED(parent)
    return m_roleNames.size();
}

int ListModelPrivate::append(QVariantMap variantMap) {
    int row = -1;

    if (variantMap.size() > 0) {
        beginInsertRows(QModelIndex(), rowCount(), rowCount());

        QList<QByteArray> keys = m_roleNamesReverse.keys();

        QMap<QString, QVariant> map;
        QByteArray key;
        foreach (key, keys) {
            if (variantMap.contains(key)) {
                map.insert(key, variantMap.value(key));
            }
            else {
                map.insert(key, QVariant());
            }
        }

        m_dataList->append(map);
        row = m_dataList->count();
        endInsertRows();
    }
    return row;
}

QMap<QString, QVariant> ListModelPrivate::remove(int i) {
    QMap<QString, QVariant> valueToBeDeleted;

    if (i >= 0 && i < m_dataList->count()) {
        valueToBeDeleted = get(i);
        beginRemoveRows(QModelIndex(), i, i);   
        m_dataList->removeAt(i);
        endRemoveRows();
    }
    return valueToBeDeleted;
}

QVariant ListModelPrivate::data(const QModelIndex &index, int role) const {
    QVariant value;
    QByteArray roleName = m_roleNames.value(role, "");

    if (!roleName.isEmpty() && index.isValid() && index.row() < m_dataList->size()) {
        QMap<QString, QVariant> map = m_dataList->at(index.row());
        value = map.value(roleName);
    }
    return value;
}

void ListModelPrivate::setProperty(int i, QString roleName, QVariant data) {
    if (i >= 0 && i < m_dataList->count()) {
        int role = roleFromRoleName(roleName);
        if (role >= 0) {
            QMap<QString, QVariant> map = m_dataList->at(i);

            map.insert(roleName, data);
            (*m_dataList)[i] = map;

            QModelIndex index = createIndex(i,role);
            emit dataChanged(index, index);
        }
    }
}

void ListModelPrivate::clear() {
    const int size = m_dataList->count();
    if (size > 0) {
        beginRemoveRows(QModelIndex(), 0, size -1);
        m_dataList->clear();
        endRemoveRows();
    }
}

QMap<QString, QVariant> ListModelPrivate::get(const int &i) const {
    if (i < m_dataList->size()) {
         return m_dataList->at(i);
    }
    return QMap<QString, QVariant>();
}

void ListModelPrivate::set(const int &i, const QMap<QString, QVariant> &map) {
    if (i < m_dataList->size()) {
        m_dataList->replace(i, map);
        if (m_roleNames.size() > 0) {
            emit dataChanged(createIndex(i,0), createIndex(i, m_roleNames.size() - 1));
        }
    }
}

int ListModelPrivate::roleFromRoleName(QString roleName) const {
    return m_roleNamesReverse.value(roleName.toUtf8(), -1);
}

void ListModelPrivate::rowsInsertedOrDeleted() {
    if (m_rowCount != rowCount()) {
        m_rowCount = rowCount();
        emit countChanged(m_rowCount);
    }
}

// --------------------------------------------------------------------------------------------------------------------
// FilterModel
// --------------------------------------------------------------------------------------------------------------------
FilterModel::FilterModel(QObject *parent)
    : QSortFilterProxyModel(parent) {
    m_sourceModel = new ListModelPrivate(parent);

    m_count = -1;

    setSourceModel(m_sourceModel);
    connect(m_sourceModel, SIGNAL(countChanged(int)), SLOT(_countChanged()));
}

FilterModel::~FilterModel() {
    delete m_sourceModel;
}

QHash<int,QByteArray> FilterModel::roleNames() const {
    return m_sourceModel->roleNames();
}

void FilterModel::setRoleNameList(QVariantList roleNameList) {
    if (m_roleNameList != roleNameList) {
        m_roleNameList = roleNameList;
        m_sourceModel->setRoleNameList(roleNameList);
        emit roleNameListChanged(roleNameList);
    }
}

QVariantList FilterModel::roleNameList() const {
    return m_roleNameList;
}

int FilterModel::count() const {
    return m_sourceModel->rowCount();
}

void FilterModel::append(QVariantMap variantMap) {
    int row = m_sourceModel->append(variantMap);
    if (m_currentDataRaw != variantMap) {
        if (row >= 0) {
            m_previousDataRaw = QMap<QString, QVariant>();
            m_currentDataRaw = variantMap;
            emit columnActionChanged(Created);
        }
    }
}

void FilterModel::remove(const int &i) {
   QMap<QString, QVariant> deletedRaw = m_sourceModel->remove(i);
   if (m_previousDataRaw != deletedRaw) {
       if (i >= 0) {
           m_previousDataRaw = deletedRaw;
           m_currentDataRaw = QMap<QString, QVariant>();
           emit columnActionChanged(Removed);
       }
   }
}

void FilterModel::setProperty(int i, QString roleName, QVariant data) {
    QMap<QString, QVariant> unchangedRaw = m_sourceModel->get(i);
    m_sourceModel->setProperty(i, roleName, data);
    QMap<QString, QVariant> changedRaw = m_sourceModel->get(i);

    if (m_currentDataRaw != changedRaw) {
        if (i >= 0) {
            m_previousDataRaw = unchangedRaw;
            m_currentDataRaw = changedRaw;
            emit columnActionChanged(Updated);
        }
    }
}

void FilterModel::clear() {
    m_sourceModel->clear();

    m_previousDataRaw = QMap<QString, QVariant>();
    m_currentDataRaw = QMap<QString, QVariant>();
    emit columnActionChanged(Cleared);
}

QMap<QString, QVariant> FilterModel::get(const int &i) {
    return m_sourceModel->get(i);
}

void FilterModel::set(const int &i, const QMap<QString, QVariant> &map) {
    QMap<QString, QVariant> previousDataRaw = m_sourceModel->get(i);

    m_sourceModel->set(i, map);
    if (m_currentDataRaw != map) {

        if (i >= 0) {
            m_previousDataRaw = previousDataRaw;
            m_currentDataRaw = map;
            emit columnActionChanged(Updated);
        }
    }
}

bool FilterModel::filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const {
    if (filterRole() >= 0) {
        QModelIndex index = sourceModel()->index(sourceRow, 0, sourceParent);
        return (sourceModel()->data(index, filterRole()).toString().contains(filterRegExp()));
    }
    else {
        return true;
    }
}

void FilterModel::setFilter(QString filterRole, QString filterText) {
    int role =  m_sourceModel->roleFromRoleName(filterRole);

    if (role >= 0) {
        setFilterRole(role);
        QRegExp rx(filterText, Qt::CaseSensitive, QRegExp::FixedString);
        setFilterRegExp(rx);
        _countChanged();
    }
    else {
       setFilterRole(-1);
    }
}

void FilterModel::clearFilter() {
     setFilterRole(-1);
     _countChanged();
}

QMap<QString, QVariant> FilterModel::getPreviousDataRaw() {
    return m_previousDataRaw;
}

QMap<QString, QVariant> FilterModel::getCurrentDataRaw() {
    return m_currentDataRaw;
}

void FilterModel::_countChanged() {
    if (m_count != count()) {
        m_count = count();
        emit countChanged(m_count);
    }
}


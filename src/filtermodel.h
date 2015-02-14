#ifndef FILTERMODEL_H
#define FILTERMODEL_H
#include <QSortFilterProxyModel>
#include <QAbstractItemModel>
#include <QModelIndex>

#include <QHash>
#include <QByteArray>
#include <QString>
#include <QDebug>

#include <QVariant>
#include <QVariantList>
#include <QVariantMap>


class ListModelPrivate: public QAbstractItemModel
{
    Q_OBJECT

public:
    explicit ListModelPrivate(QObject *parent = 0);
    ~ListModelPrivate();

    void setRoleNameList(QVariantList variantList);
    QHash<int,QByteArray> roleNames() const;

    QModelIndex parent(const QModelIndex &child) const;
    QModelIndex index(int row, int column, const QModelIndex &parent = QModelIndex()) const;
    int rowCount(const QModelIndex &parent = QModelIndex()) const;
    int columnCount(const QModelIndex &parent  = QModelIndex()) const;

    int append(QVariantMap variantMap);
    QMap<QString, QVariant> remove(int i);
    void setProperty(int i, QString roleName, QVariant data);
    void clear();

    QMap<QString, QVariant> get(const int &i) const;
    void set(const int &index, const QMap<QString, QVariant> &map);

    QVariant data(const QModelIndex &index, int role) const;

    int roleFromRoleName(QString roleName) const;

signals:
    void countChanged(int count);

private slots:
    void rowsInsertedOrDeleted();

private:
    QHash<int, QByteArray> m_roleNames;
    QHash<QByteArray, int> m_roleNamesReverse;
    QList<QMap<QString, QVariant> >* m_dataList;
    int m_rowCount;

};

class FilterModel: public QSortFilterProxyModel
{
    Q_OBJECT
    Q_ENUMS(ColumnAction)
    Q_PROPERTY(QVariantList roleNames READ roleNameList WRITE setRoleNameList NOTIFY roleNameListChanged)
    Q_PROPERTY(int count READ count NOTIFY countChanged)

    Q_ENUMS(Action)

public:
    FilterModel(QObject *parent = 0);
    ~FilterModel();

    enum ColumnAction
    {
        Created, Removed, Updated, Deleted, Cleared
    };

    QHash<int,QByteArray> roleNames() const;

    void setRoleNameList(QVariantList roleNameList);
    QVariantList roleNameList() const;

    int count() const;

    Q_INVOKABLE void append(QVariantMap variantMap);
    Q_INVOKABLE void remove(const int &i);
    Q_INVOKABLE void setProperty(int i, QString roleName, QVariant data);
    Q_INVOKABLE void clear();
    Q_INVOKABLE QMap<QString, QVariant> get(const int &i);
    Q_INVOKABLE void set(const int &i, const QMap<QString, QVariant> &map);

    Q_INVOKABLE void setFilter(QString filterRole, QString filterText);
    Q_INVOKABLE void clearFilter();

    Q_INVOKABLE QMap<QString, QVariant> getPreviousDataRaw();
    Q_INVOKABLE QMap<QString, QVariant> getCurrentDataRaw();

signals:
    void roleNameListChanged(QVariantList roleNames);
    void countChanged(int count);
    void countSourceChanged(int countSource);
    void dataRawChanged();
    void columnActionChanged(ColumnAction columnAction);

private slots:
    void _countChanged();

protected:
    bool filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const;

private:
    ListModelPrivate *m_sourceModel;
    QVariantList m_roleNameList;

    ColumnAction m_columnAction;

    QVariantMap m_previousDataRaw;
    QVariantMap m_currentDataRaw;

    int m_count;

};

#endif // FILTERMODEL_H

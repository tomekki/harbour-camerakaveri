#ifndef ENUMS_H
#define ENUMS_H

#include <QObject>

class Enums : public QObject
{
    Q_OBJECT
    Q_ENUMS(PageStatus)

public:
     explicit Enums(QObject *parent = 0);
     ~Enums();


    enum PageStatus
    {
        INIT, LOADING, DISPLAY_IMAGE, ERROR
    };

};

#endif // ENUMS_H
